# -FPGA-Quadcopter-Flight-Controller
The goal of this final project was to build a quadcopter flight-controller using an FPGA-based System-on-Chip architecture rather than a traditional microcontroller flight controller, enabling highly parallel, deterministic real-time control loops with lower latency and improved timing predictability. Specifically, we implemented a MicroBlaze soft processor system in Vivado and designed multiple custom AXI-Lite peripherals to interface with real-world quadcopter hardware:

- Radio receiver input (FlySky receiver) for pilot commands (throttle, roll, pitch, yaw)

- Electronic Speed Controllers (ESCs) requiring accurate PWM motor signals

- Inertial Measurement Unit (IMU) (gyro/accelerometer) for stabilization behavior

The general control flow:
(1) Transmitter outputs a signal to the Receiver -> (2) Signal is decoded by the FPGA -> (3) FPGA syncs this signal with the IMU data that it is reading -> (4) FPGA runs a control loop via the MicroBlaze and outputs PWM signals to individual ESC pins -> (5) All 4 motors on the Quadcopter are then driven at once on one of the 4 channels

With pilot stick input, the quad responds by changing motor outputs appropriately (manual control). When the pilot lets go of the sticks, the system uses IMU feedback to self-stabilize, opposing the measured tilt/rotation. The FPGA-based architecture remains modular and testable: each hardware interface is packaged as an independent IP block connected through AXI-Lite. In other words, the project objective was not simply “spin motors,” but to design a complete hardware-software co-designed control system with real-time constraints and physical hardware validation.

Beyond the functional outcome, the project provided valuable experience in real-time FPGA development, hardware/software co-design, and debugging physical control applications. The modular AXI-based architecture lends itself naturally to future extensions, such as PID control loops, improved sensor fusion, and autonomous flight modes.
