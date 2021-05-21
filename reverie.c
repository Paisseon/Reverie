#import <stdio.h>
#import <mach/mach.h>
#import <CoreFoundation/CoreFoundation.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/pwr_mgt/IOPMLib.h>

int main() {
	mach_port_t master_device_port = kIOMasterPortDefault;
	kern_return_t v5;
	io_service_t v3;

	setuid(0); // root permission or something
	setuid(0);
	setgid(0);
	setgid(0);

	v3 = IORegistryEntryFromPath(kIOMasterPortDefault, "IOPower:/IOPowerConnection/IOPMrootDomain"); // ref pwr_mgt root domain
	if (!v3) return KERN_FAILURE;
	v4 = IOPMFindPowerManagement(master_device_port); // ref pwr_mgt
	if (!v4) return KERN_FAILURE;
	v5 = IOPMSleepSystem(v4); // this is hibernate
	return v5;
}