

// test with accel and imu and everything working

#include "xparameters.h"
#include "xil_io.h"
#include "xil_printf.h"
#include "sleep.h"
#include "xiic.h"
#include "xstatus.h"
#include <stdint.h>
#include <math.h>

// config

// define loop time for updating motor config while in flight
#define LOOP_DELAY_US          4000    // 4ms = 250Hz
#define DT                     0.004f

// flight constants -- safety
#define MAX_BANK_ANGLE         30.0f   // max tilt
#define RC_DEADBAND            10

// PID loop + constants
#define KP_LEVEL_ROLL          4.0f
#define KP_LEVEL_PITCH         4.0f
#define KP_RATE_ROLL           2.5f
#define KP_RATE_PITCH          2.5f
#define KP_RATE_YAW            5.0f

// addresses from xparameters.h for receiever and pwm based on vivado mapping to physical hardware
#define RECEIVER_BASEADDR      XPAR_RECEIVER_IP_V1_0_0_BASEADDR
#define RX_CH1_WIDTH_REG       (RECEIVER_BASEADDR + 0x00)
#define RX_CH2_WIDTH_REG       (RECEIVER_BASEADDR + 0x04)
#define RX_CH3_WIDTH_REG       (RECEIVER_BASEADDR + 0x08)
#define RX_CH4_WIDTH_REG       (RECEIVER_BASEADDR + 0x0C)

#define PWM_BASEADDR           XPAR_PWM_IP_0_S00_AXI_BASEADDR
#define PWM_PERIOD_REG         (PWM_BASEADDR + 0x00)
// 4 motors
#define PWM_DUTY0_REG          (PWM_BASEADDR + 0x04)
#define PWM_DUTY1_REG          (PWM_BASEADDR + 0x08)
#define PWM_DUTY2_REG          (PWM_BASEADDR + 0x0C)
#define PWM_DUTY3_REG          (PWM_BASEADDR + 0x10)

#define IIC_DEVICE_ID          XPAR_IIC_0_DEVICE_ID
// imu
#define IMU_ADDR               0x68
#define REG_PWR_MGMT_1         0x6B
// this is where u read accel according to datasheet
#define REG_ACCEL_XOUT_H       0x3B  //read 14 bytes starting here

//constants
#define TICKS_PER_US           100U
#define PWM_PERIOD_TICKS       2000000U
#define ESC_MIN_PULSE_TICKS    100000U
#define ESC_MAX_PULSE_TICKS    190000U
#define RX_MIN_TICKS           90000U
#define RX_MAX_TICKS           210000U
#define RX_MID_TICKS           150000U


// scaling factor for imu self test from datasheet
#define GYRO_SCALE_FACTOR      131.0f
#define RAD_TO_DEG             57.2957795f

static XIic IicInstance;

// states to update while loop runs in real time
float g_roll_angle = 0.0f;
float g_pitch_angle = 0.0f;
float g_gyro_bias_x = 0.0f;
float g_gyro_bias_y = 0.0f;
float g_gyro_bias_z = 0.0f;

// return 32 bit value
static uint32_t clamp_u32(uint32_t x, uint32_t lo, uint32_t hi) {
    if (x < lo) return lo;
    if (x > hi) return hi;
    return x;
}

static int32_t clamp_s32(int32_t x, int32_t lo, int32_t hi) {
    if (x < lo) return lo;
    if (x > hi) return hi;
    return x;
}

//imu test
static int imu_write_reg(u8 reg, u8 value) {
    u8 buf[2] = {reg, value};
    return XIic_Send(IicInstance.BaseAddress, IMU_ADDR, buf, 2, XIIC_STOP) == 2 ? XST_SUCCESS : XST_FAILURE;
}

static int imu_read_bytes(u8 start_reg, u8 *buf, unsigned length) {
    XIic_Send(IicInstance.BaseAddress, IMU_ADDR, &start_reg, 1, XIIC_REPEATED_START);
    return XIic_Recv(IicInstance.BaseAddress, IMU_ADDR, buf, length, XIIC_STOP) == length ? XST_SUCCESS : XST_FAILURE;
}

// reads accel and gyro together (14 bytes) for speed and sync
static int imu_read_all(float *ax, float *ay, float *az, float *gx, float *gy, float *gz) {
    u8 data[14];
    if (imu_read_bytes(REG_ACCEL_XOUT_H, data, 14) != XST_SUCCESS) return XST_FAILURE;

    int16_t raw_ax = (int16_t)((data[0] << 8) | data[1]);
    int16_t raw_ay = (int16_t)((data[2] << 8) | data[3]);
    int16_t raw_az = (int16_t)((data[4] << 8) | data[5]);
    // data[6,7] is temp, skip
    int16_t raw_gx = (int16_t)((data[8] << 8) | data[9]);
    int16_t raw_gy = (int16_t)((data[10] << 8) | data[11]);
    int16_t raw_gz = (int16_t)((data[12] << 8) | data[13]);

    *ax = (float)raw_ax;
    *ay = (float)raw_ay;
    *az = (float)raw_az;

    // gyro to degrees per second based on scaling factor
    *gx = ((float)raw_gx / GYRO_SCALE_FACTOR) - g_gyro_bias_x;
    *gy = ((float)raw_gy / GYRO_SCALE_FACTOR) - g_gyro_bias_y;
    *gz = ((float)raw_gz / GYRO_SCALE_FACTOR) - g_gyro_bias_z;

    return XST_SUCCESS;
}

//calibration for the gyro to define what "zero" is
static void calibrate_gyro() {
    float ax, ay, az, gx, gy, gz;
    float sum_x = 0, sum_y = 0, sum_z = 0;
    int samples = 500;

    xil_printf("calibrating Gyro...\r\n");
    for (int i = 0; i < samples; i++) {
        imu_read_all(&ax, &ay, &az, &gx, &gy, &gz);
        sum_x += ((float)((int16_t)(gx * GYRO_SCALE_FACTOR))) / GYRO_SCALE_FACTOR;
        sum_y += ((float)((int16_t)(gy * GYRO_SCALE_FACTOR))) / GYRO_SCALE_FACTOR;
        sum_z += ((float)((int16_t)(gz * GYRO_SCALE_FACTOR))) / GYRO_SCALE_FACTOR;
        usleep(2000);
    }
    g_gyro_bias_x = sum_x / samples;
    g_gyro_bias_y = sum_y / samples;
    g_gyro_bias_z = sum_z / samples;
    xil_printf("Bias X: %d, Y: %d, Z: %d\r\n", (int)g_gyro_bias_x, (int)g_gyro_bias_y, (int)g_gyro_bias_z);
}

//initialization of pwm (which actually outputs to motors)

static void pwm_init(void)
{
    Xil_Out32(PWM_PERIOD_REG, PWM_PERIOD_TICKS);
    Xil_Out32(PWM_DUTY0_REG, ESC_MIN_PULSE_TICKS);
    Xil_Out32(PWM_DUTY1_REG, ESC_MIN_PULSE_TICKS);
    Xil_Out32(PWM_DUTY2_REG, ESC_MIN_PULSE_TICKS);
    Xil_Out32(PWM_DUTY3_REG, ESC_MIN_PULSE_TICKS);
}
static void hardware_init() {
    pwm_init();

    // initialize i2c
    XIic_Config *cfg = XIic_LookupConfig(IIC_DEVICE_ID);
    XIic_CfgInitialize(&IicInstance, cfg, cfg->BaseAddress);
    XIic_Start(&IicInstance);

    // wakeup the IMU
    imu_write_reg(REG_PWR_MGMT_1, 0x00);
    usleep(50000);
}

// main functions where we call all helpers defined above
int main(void) {
    hardware_init();

    xil_printf("=== FLIGHT CONTROLLER v2.0 (Angle Mode) ===\r\n");
    calibrate_gyro();

    // assume flat config at power on
    g_roll_angle = 0.0f;
    g_pitch_angle = 0.0f;

    while (1) {
        //estimate gyro state based on readings and make sure gyro is fine
        float ax, ay, az, gx, gy, gz;
        if (imu_read_all(&ax, &ay, &az, &gx, &gy, &gz) != XST_SUCCESS) {
            continue;
        }

        // calculate accelerometer angles using "angle mode"

        float accel_pitch = atan2(ax, sqrt(ay*ay + az*az)) * RAD_TO_DEG;
        float accel_roll  = atan2(ay, sqrt(ax*ax + az*az)) * RAD_TO_DEG;


        // basic complementary filter to mix gyro intergration with accel data
        // this removes gyro drift while ignoring accel vibration
        g_pitch_angle = 0.98f * (g_pitch_angle + gx * DT) + 0.02f * accel_pitch;
        g_roll_angle  = 0.98f * (g_roll_angle  + gy * DT) + 0.02f * accel_roll;

        // input from transmitter
        uint32_t raw_ch1 = clamp_u32(Xil_In32(RX_CH1_WIDTH_REG), RX_MIN_TICKS, RX_MAX_TICKS); // Roll
        uint32_t raw_ch2 = clamp_u32(Xil_In32(RX_CH2_WIDTH_REG), RX_MIN_TICKS, RX_MAX_TICKS); // Pitch
        uint32_t raw_ch3 = clamp_u32(Xil_In32(RX_CH3_WIDTH_REG), RX_MIN_TICKS, RX_MAX_TICKS); // Thr
        uint32_t raw_ch4 = clamp_u32(Xil_In32(RX_CH4_WIDTH_REG), RX_MIN_TICKS, RX_MAX_TICKS); // Yaw

        // actual PID loop logic

        // map the sticks to angles
        float stick_roll_norm  = ((float)raw_ch1 - RX_MID_TICKS) / 50000.0f;
        float stick_pitch_norm = ((float)raw_ch2 - RX_MID_TICKS) / 50000.0f;
        float stick_yaw_norm   = ((float)raw_ch4 - RX_MID_TICKS) / 50000.0f;

        // deadband
        if (fabs(stick_roll_norm) < 0.05f) stick_roll_norm = 0.0f;
        if (fabs(stick_pitch_norm) < 0.05f) stick_pitch_norm = 0.0f;
        if (fabs(stick_yaw_norm) < 0.05f) stick_yaw_norm = 0.0f;

        float desired_roll = stick_roll_norm * MAX_BANK_ANGLE;
        float desired_pitch = stick_pitch_norm * MAX_BANK_ANGLE;

        float error_roll_angle = desired_roll - g_roll_angle;
        float error_pitch_angle = desired_pitch - g_pitch_angle;

        float target_roll_rate = error_roll_angle * KP_LEVEL_ROLL;
        float target_pitch_rate = error_pitch_angle * KP_LEVEL_PITCH;
        float target_yaw_rate = stick_yaw_norm * 150.0f; // Yaw is Rate only (max 150 deg/s)


        float error_roll_rate = target_roll_rate - gy;
        float error_pitch_rate = target_pitch_rate - gx;
        float error_yaw_rate = target_yaw_rate - gz;

        int32_t roll_pid  = (int32_t)(error_roll_rate  * KP_RATE_ROLL  * 10.0f); // Scaling for ticks
        int32_t pitch_pid = (int32_t)(error_pitch_rate * KP_RATE_PITCH * 10.0f);
        int32_t yaw_pid   = (int32_t)(error_yaw_rate   * KP_RATE_YAW   * 10.0f);

        // mixing motor signals
        uint32_t throttle = raw_ch3;

        // low throttle kill outputs
        if (throttle < (ESC_MIN_PULSE_TICKS + 5000)) {
            roll_pid = 0; pitch_pid = 0; yaw_pid = 0;
            g_roll_angle = accel_roll;
            g_pitch_angle = accel_pitch;
        }

        int32_t m_fl = (int32_t)throttle + roll_pid - pitch_pid - yaw_pid;
        int32_t m_fr = (int32_t)throttle - roll_pid - pitch_pid + yaw_pid;
        int32_t m_bl = (int32_t)throttle + roll_pid + pitch_pid + yaw_pid;
        int32_t m_br = (int32_t)throttle - roll_pid + pitch_pid - yaw_pid;

        // clamp to esc range
        m_fl = clamp_s32(m_fl, ESC_MIN_PULSE_TICKS, ESC_MAX_PULSE_TICKS);
        m_fr = clamp_s32(m_fr, ESC_MIN_PULSE_TICKS, ESC_MAX_PULSE_TICKS);
        m_bl = clamp_s32(m_bl, ESC_MIN_PULSE_TICKS, ESC_MAX_PULSE_TICKS);
        m_br = clamp_s32(m_br, ESC_MIN_PULSE_TICKS, ESC_MAX_PULSE_TICKS);

        Xil_Out32(PWM_DUTY0_REG, m_fl);
        Xil_Out32(PWM_DUTY1_REG, m_br);
        Xil_Out32(PWM_DUTY2_REG, m_bl);
        Xil_Out32(PWM_DUTY3_REG, m_fr);

        usleep(LOOP_DELAY_US);
    }
    return 0;
}
