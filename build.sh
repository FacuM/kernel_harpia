KERNEL_DIR=$PWD
TOOLCHAINDIR=$(pwd)/toolchain/linaro-7.2
DATE=$(date +"%d%m%Y")
KERNEL_NAME="BLEEDING_EDGE-Kernel"

export ARCH=arm
# export KBUILD_BUILD_HOST="SEND_NUDES__PLEASE"
export CROSS_COMPILE=$TOOLCHAINDIR/bin/arm-eabi-
export USE_CCACHE=1

if [ -e  arch/arm/boot/zImage ];
then
rm arch/arm/boot/zImage #Just to make sure it doesn't make flashable zip with previous zImage
fi;

if [ -z $2 ] || [ -z $3 ]
then
 printf "\nUsage: \n\n\tbash build.sh [thread_amount] device_codename maintainer_username\n\n\tNOTE: '[thread_amount]' can be an integer or 'auto'.\n\n"
 exit 1
fi
export DEVICE="-$2-"
export KBUILD_BUILD_USER="$3"
Anykernel_DIR=$KERNEL_DIR/Anykernel2/$DEVICE
mkdir -p $Anykernel_DIR
VER="-v70"
TYPE="-N"
export FINAL_ZIP="$KERNEL_NAME""$DEVICE""$DATE""$TYPE""$VER".zip
if [ "$1" == 'auto' ]
then
 t=$(nproc --all)
else
 t=$1
fi
printf "\nTHREADS: $t\nDEVICE: $2\nMAINTAINER: $3\n\n"
echo "Making kernel binary"
make $2_defconfig
make -j$( nproc --all ) zImage

if [ -e  arch/arm/boot/zImage ];
then
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
else
echo "Kernel not compiled,fix errors and compile again"
exit 1
fi;

