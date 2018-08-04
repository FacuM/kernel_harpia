if [ -z $2 ] || [ -z $3 ]
then
 printf "\nUsage: \n\n\tbash build.sh [thread_amount] device_codename maintainer_username\n\n\tNOTE: '[thread_amount]' can be an integer or 'auto'.\n\n"
 exit 1
fi

KERNEL_DIR=$PWD
TOOLCHAINDIR=$(pwd)/toolchain/arm-linux-gnueabi
DATE=$(date +"%d%m%Y")
KERNEL_NAME="BLEEDING_EDGE-Kernel"

# Merge the toolchain parts, unpack it and remove compressed files.

echo "=> Preparing toolchain"
cd $TOOLCHAINDIR
echo "- Merging files"
cat arm-linux-gnueabi.tar.xz.part* > arm-linux-gnueabi.tar.xz
echo "- Unpacking files"
tar xf 'arm-linux-gnueabi.tar.xz'
if [ $? -ne 0 ]
then
 echo "Unable to prepare the toolchain, please check the errors above."
 exit 1
fi
cd $KERNEL_DIR

export ARCH=arm
# export KBUILD_BUILD_HOST="SEND_NUDES__PLEASE"
export CROSS_COMPILE=$TOOLCHAINDIR/bin/arm-linux-gnueabi-
export USE_CCACHE=1

if [ -e  arch/arm/boot/zImage ];
then
rm arch/arm/boot/zImage #Just to make sure it doesn't make flashable zip with previous zImage
fi;

export DEVICE="$2"
export KBUILD_BUILD_USER="$3"
Anykernel_DIR=$KERNEL_DIR/Anykernel2/$DEVICE
mkdir -p $Anykernel_DIR
VER="-v70"
TYPE="-N"
export FINAL_ZIP="$KERNEL_NAME"-"$DEVICE"-"$DATE""$TYPE""$VER".zip
if [ "$1" == 'auto' ]
then
 t=$(nproc --all)
else
 t=$1
fi
printf "\nTHREADS: $t\nDEVICE: $2\nMAINTAINER: $3\n\n"
echo "=> Making kernel binary..."
make $2_defconfig
make -j$t zImage
if [ $? -ne 0 ]
then
 echo "Kernel compilation failed, can't continue."
 exit 1
fi
echo "=> Making modules..."
make -j$t modules
if [ $? -ne 0 ]
then
 echo "Module compilation failed, can't continue."
 exit 1
fi
make -j$t modules_install INSTALL_MOD_PATH=modules INSTALL_MOD_STRIP=1
if [ $? -ne 0 ]
then
 echo "Module installation failed, can't continue."
 exit 1
fi
mkdir -p "$Anykernel_DIR/modules/system/lib/modules/pronto"
find modules/ -name '*.ko' -type f -exec cp '{}' "$Anykernel_DIR/modules/system/lib/modules/" \;
cp "$Anykernel_DIR/modules/system/lib/modules/wlan.ko" "$Anykernel_DIR/modules/system/lib/modules/pronto/pronto_wlan.ko"

echo "Kernel compilation completed"

cp  $KERNEL_DIR/arch/arm/boot/zImage $Anykernel_DIR

cd $Anykernel_DIR

echo "Making Flashable zip"

echo "Generating changelog"

if [ -e $Anykernel_DIR/changelog.txt ];
then
rm $Anykernel_DIR/changelog.txt
fi;

git log --graph --pretty=format:'%s' --abbrev-commit -n 200  > changelog.txt

echo "Changelog generated"

if [ -e $Anykernel_DIR/*.zip ];
then
rm *.zip
fi;

zip -r9 $FINAL_ZIP * -x *.zip $FINAL_ZIP > /dev/null

echo "Flashable zip Created"
echo "Flashable zip is stored in $Anykernel_DIR folder with name $FINAL_ZIP"
exit 0
