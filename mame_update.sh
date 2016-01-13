#! /bin/bash
# MAME_Update v0.4
#
# Script to build or update a MAME directory in OS X from source directories of ROMs, CHDs, and EXTRAs
#
# Version History
##################
#
# 0.1: Initial release (12/4/2015)
# 0.2: Preserve artwork timestamps (12/5/2015)
# 0.3: Single-quoted echoes to avoid a substitution, sped up ROM sync (12/5/2015)
# 0.4: All cabinet and device images are now consolidated in the /cabdevs directory
#      Fix QMC version number in cleanup section
#      Fix SDLMAME ZIP file version number (1/12/2016)

#Source and destination folders
rom_src=/Volumes/EMULATION
mame_dest=/Volumes/Stadium\ Events/Games/MAME

# New version numbers
mame_ver="0.169"
extras_ver="0.168"

# Set directories
roms="$rom_src"/MAME\ $mame_ver\ ROMs/
chds="$rom_src"/MAME\ $mame_ver\ CHDs/
swlist_roms="$rom_src"/MAME\ $mame_ver\ Software\ List\ ROMs/
swlist_chds="$rom_src"/MAME\ $mame_ver\ Software\ List\ CHDs/
extras="$rom_src"/MAME\ $extras_ver\ EXTRAs

# Save working directory
cwd=$(pwd)

# Download SDLMAME, catver.ini, category.ini
echo 'Downloading MAME files'
sleep 2
mkdir -p $TMPDIR/downloads && cd $_
curl -#O http://sdlmame.lngn.net/mame0${mame_ver: -3}-64bit.zip                                              #SDLMAME
curl -#O http://www.progettosnaps.net/MAME/pS_MAME_catver.zip                                                #catver.ini
curl -#o category.ini "http://sourceforge.net/p/qmc2/code/HEAD/tree/trunk/data/cat/category.ini?format=raw"  #category.ini

# Installing base MAME
echo 'Installing base MAME'
unzip -q mame0${mame_ver: -3}-64bit.zip
ls "$extras" > $TMPDIR/excludes
echo "roms" >> $TMPDIR/excludes
echo "vdo" >> $TMPDIR/excludes
echo "cheat*" >> $TMPDIR/excludes
echo "icons.zip" >> $TMPDIR/excludes
echo "catver.ini" >> $TMPDIR/excludes
echo "category.ini" >> $TMPDIR/excludes
rsync -acviP --delete --exclude '*DS_Store*' --exclude-from=$TMPDIR/excludes $TMPDIR/downloads/mame0${mame_ver: -3}-64bit/ "$mame_dest"

# Updating ROMs and CHDs
echo 'Updating ROMs and CHDs. This may take a while.'
sleep 2
rsync -aviP --delete --exclude '*_ReadMe_*' "$roms" "$chds" "$swlist_roms" "$swlist_chds" "$mame_dest/roms"

#Updating extras
echo 'Updating extras'
sleep 2
mv -f category.ini "$mame_dest"
unzip -q pS_MAME_catver.zip
mv -f catver.ini "$mame_dest"
ls "$TMPDIR/downloads/mame0${mame_ver: -3}-64bit/" > $TMPDIR/excludes
cat << EOF >> $TMPDIR/excludes
_ReadMe_.txt
artwork
cheat*
category.ini
catver.ini
icons*
roms
vdo
EOF
rsync -aviP --delete --exclude-from=$TMPDIR/excludes "$extras/" "$mame_dest"
rsync -aviP "$TMPDIR/downloads/mame0${mame_ver: -3}-64bit/samples/" "$mame_dest/samples"

#ARTWORK
echo 'Updating artwork'
sleep 2
mkdir -p $TMPDIR/mameart
cd "$extras/artwork"
for zipfile in *.zip; do
    exdir="${zipfile%.zip}"
    mkdir "$TMPDIR/mameart/$exdir" && unzip -d "$TMPDIR/mameart/$exdir" "$zipfile"
done
rsync -rlgocDviP --delete --exclude '*DS_Store*' $TMPDIR/mameart/ "$mame_dest/artwork"
rsync -acviP "$TMPDIR/downloads/mame0${mame_ver: -3}-64bit/artwork/" $TMPDIR/mameart/

#CHEAT
echo 'Updating cheats'
sleep 2
mkdir -p $TMPDIR/cheat
7za x -o$TMPDIR/cheat "$extras/cheat.7z"
rsync -acviP --delete $TMPDIR/cheat/ "$mame_dest/cheat"

#ICONS
echo 'Updating icons'
sleep 2
cd "$extras/icons"
zip -0 $TMPDIR/icons.zip *
find ./ -iname "*.ico" | xargs -L 1000 zip -0 $TMPDIR/icons.zip
rsync -acviP $TMPDIR/icons.zip "$mame_dest/icons.zip"


#QMC2
read -p "MAME update complete. Install QMC2? (Y/N) " qmc
case $qmc in
  [Yy]* )
    qmc_ver=`echo "$mame_ver 10 1.1" | awk '{printf "%.2f", $1 * $2 - $3}'`;
    cd $TMPDIR/downloads
    curl -LO http://downloads.sourceforge.net/project/qmc2/qmc2/$qmc_ver/qmc2-macosx-intel-$qmc_ver.dmg;
    hdiutil attach $TMPDIR/downloads/qmc2-macosx-intel-$qmc_ver.dmg;
    open /Volumes/QMC2-$qmc_ver/QMC2.mpkg;;
  [Nn]* )
    ;;
esac

#Cleanup
cd $cwd
unset cwd rom_src mame_dest mame_ver extras_ver qmc_ver roms chds swlist_roms swlist_chds extras qmc
if [ -d QMC2-$qmc_ver ]; then hdiutil attach $TMPDIR/downloads/qmc2-macosx-intel-$qmc_ver.dmg; fi
rm -r $TMPDIR/mameart $TMPDIR/excludes $TMPDIR/cheat $TMPDIR/icons.zip $TMPDIR/downloads
echo 'Script complete!'
