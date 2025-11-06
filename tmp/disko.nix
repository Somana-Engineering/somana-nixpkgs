{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/mmcblk1";  # your SSD device
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00"; # EFI System Partition
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
	    };
	  };
	  root = {
            size = "100%";
	    content = {
 	      type = "filesystem";
	      format = "ext4";
    	      mountpoint = "/";
	    };
	  };
	};
      };
    };
   };
}
