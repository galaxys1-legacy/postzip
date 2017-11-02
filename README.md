### post processing zip after building

We need to use the ramdisk.img with Nougat adb. 

And CM Simple recovery is shit. So replace that with prebuilt TWRP.  

### Usage

Clone this repo as postzip in source root dir.

`./postzip/flash.sh out/target/product/name/lineage-.zip `

This will start sideloading the lineage zip.
Then prompt to sideload again for patched ramdisk. 

If you missed the side load just add `oops` as second argument.

