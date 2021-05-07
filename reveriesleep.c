#import <stdio.h>
#import <mach/mach.h>
#import <CoreFoundation/CoreFoundation.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/pwr_mgt/IOPMLib.h>

int main() {
	mach_port_t master = kIOMasterPortDefault;
	kern_return_t err = KERN_SUCCESS;
	io_service_t ref = MACH_PORT_NULL;

	setuid(0); // root permission or something
	setuid(0);
	setgid(0);
	setgid(0);

	ref = IORegistryEntryFromPath(kIOMasterPortDefault, "IOPower:/IOPowerConnection/IOPMrootDomain"); // Get a reference to the powermanagement rootdomain
	if(IO_OBJECT_NULL == ref) return KERN_FAILURE;
	ref = IOPMFindPowerManagement(master); // get a powermanagement reference for the system
	if(IO_OBJECT_NULL == ref) return KERN_FAILURE;
	err = IOPMSleepSystem(ref); // send the hibernate mach message to IOPowerManagement
	if(KERN_SUCCESS != err) return KERN_FAILURE;
	return err;
}