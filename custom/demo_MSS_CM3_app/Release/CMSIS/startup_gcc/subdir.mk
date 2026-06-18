################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../CMSIS/startup_gcc/newlib_stubs.c 

S_UPPER_SRCS += \
../CMSIS/startup_gcc/startup_m2sxxx.S 

OBJS += \
./CMSIS/startup_gcc/newlib_stubs.o \
./CMSIS/startup_gcc/startup_m2sxxx.o 

S_UPPER_DEPS += \
./CMSIS/startup_gcc/startup_m2sxxx.d 

C_DEPS += \
./CMSIS/startup_gcc/newlib_stubs.d 


# Each subdirectory must supply rules for building sources it contributes
CMSIS/startup_gcc/%.o: ../CMSIS/startup_gcc/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: Cross ARM C Compiler'
	arm-none-eabi-gcc -mcpu=cortex-m3 -mthumb -Os -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections  -g -I"C:\Projects\BLDS\USBFlash\github\dg0454\custom\demo_MSS_CM3_app\CMSIS" -I"C:\Projects\BLDS\USBFlash\github\dg0454\custom\demo_MSS_CM3_app\CMSIS\startup_gcc" -I"C:\Projects\BLDS\USBFlash\github\dg0454\custom\demo_MSS_CM3_app\drivers" -I"C:\Projects\BLDS\USBFlash\github\dg0454\custom\demo_MSS_CM3_app\drivers\mss_hpdma" -I"C:\Projects\BLDS\USBFlash\github\dg0454\custom\demo_MSS_CM3_app\drivers\mss_nvm" -I"C:\Projects\BLDS\USBFlash\github\dg0454\custom\demo_MSS_CM3_app\drivers\mss_timer" -I"C:\Projects\BLDS\USBFlash\github\dg0454\custom\demo_MSS_CM3_app\drivers\mss_uart" -I"C:\Projects\BLDS\USBFlash\github\dg0454\custom\demo_MSS_CM3_app\drivers_config" -I"C:\Projects\BLDS\USBFlash\github\dg0454\custom\demo_MSS_CM3_app\drivers_config\sys_config" -I"C:\Projects\BLDS\USBFlash\github\dg0454\custom\demo_MSS_CM3_app\hal" -I"C:\Projects\BLDS\USBFlash\github\dg0454\custom\demo_MSS_CM3_app\hal\CortexM3" -I"C:\Projects\BLDS\USBFlash\github\dg0454\custom\demo_MSS_CM3_app\hal\CortexM3\GNU" -std=gnu11 --specs=cmsis.specs -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

CMSIS/startup_gcc/%.o: ../CMSIS/startup_gcc/%.S
	@echo 'Building file: $<'
	@echo 'Invoking: Cross ARM GNU Assembler'
	arm-none-eabi-gcc -mcpu=cortex-m3 -mthumb -Os -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections  -g -x assembler-with-cpp -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


