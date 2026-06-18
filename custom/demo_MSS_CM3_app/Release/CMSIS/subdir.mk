################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../CMSIS/system_m2sxxx.c 

OBJS += \
./CMSIS/system_m2sxxx.o 

C_DEPS += \
./CMSIS/system_m2sxxx.d 


# Each subdirectory must supply rules for building sources it contributes
CMSIS/%.o: ../CMSIS/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: Cross ARM C Compiler'
	arm-none-eabi-gcc -mcpu=cortex-m3 -mthumb -Os -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections  -g -I"C:\Projects\BLDS\USBFlash\github\dg0454\custom\demo_MSS_CM3_app\CMSIS" -I"C:\Projects\BLDS\USBFlash\github\dg0454\custom\demo_MSS_CM3_app\CMSIS\startup_gcc" -I"C:\Projects\BLDS\USBFlash\github\dg0454\custom\demo_MSS_CM3_app\drivers" -I"C:\Projects\BLDS\USBFlash\github\dg0454\custom\demo_MSS_CM3_app\drivers\mss_hpdma" -I"C:\Projects\BLDS\USBFlash\github\dg0454\custom\demo_MSS_CM3_app\drivers\mss_nvm" -I"C:\Projects\BLDS\USBFlash\github\dg0454\custom\demo_MSS_CM3_app\drivers\mss_timer" -I"C:\Projects\BLDS\USBFlash\github\dg0454\custom\demo_MSS_CM3_app\drivers\mss_uart" -I"C:\Projects\BLDS\USBFlash\github\dg0454\custom\demo_MSS_CM3_app\drivers_config" -I"C:\Projects\BLDS\USBFlash\github\dg0454\custom\demo_MSS_CM3_app\drivers_config\sys_config" -I"C:\Projects\BLDS\USBFlash\github\dg0454\custom\demo_MSS_CM3_app\hal" -I"C:\Projects\BLDS\USBFlash\github\dg0454\custom\demo_MSS_CM3_app\hal\CortexM3" -I"C:\Projects\BLDS\USBFlash\github\dg0454\custom\demo_MSS_CM3_app\hal\CortexM3\GNU" -std=gnu11 --specs=cmsis.specs -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


