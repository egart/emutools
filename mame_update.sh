#!/usr/bin/env bash
# MAME_Update v0.6
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
# 0.5: Large revision in the content of EXTRAs
#      Extras version now matches MAME version
#      VideoSnaps now included
#      No longer any need for separate catver and category files
# 0.6: Update SDLMAME download link
# 0.7: Update SDLMAME download link

# TODO: quiet vs debug mode
#       list changes

#Source and destination folders
rom_src=/Volumes/EMULATION
mame_dest=/Volumes/Stadium\ Events/Games/MAME
#mame_dest=/Volumes/Bababooey/Temp/Rebuilds/new\ mame

# New version numbers
mame_ver="0.208"

# Set directories
roms="$rom_src"/MAME\ $mame_ver\ ROMs/
chds="$rom_src"/MAME\ $mame_ver\ CHDs/
swlist_roms="$rom_src"/MAME\ $mame_ver\ Software\ List\ ROMs/
swlist_chds="$rom_src"/MAME\ $mame_ver\ Software\ List\ CHDs/
extras="$rom_src"/MAME\ $mame_ver\ EXTRAs
multi="$rom_src"/MAME\ $mame_ver\ Multimedia

# Save working directory
cwd=$(pwd)

# Download SDLMAME
echo 'Downloading MAME files' && sleep 2
mkdir -p $TMPDIR/downloads && cd $_
curl -#O http://mirrors.xmission.com/mame/mac/sdlmame/mame0${mame_ver: -3}-64bit.zip

# Installing base MAME
echo 'Installing base MAME' && sleep 2
unzip -q mame0${mame_ver: -3}-64bit.zip
find "$extras" -depth 1 -exec basename -s.zip {} + | sort > $TMPDIR/excludes
echo "roms" >> $TMPDIR/excludes
echo "cheat" >> $TMPDIR/excludes
echo "icons.zip" >> $TMPDIR/excludes
echo "samples" >> $TMPDIR/excludes
echo "soundtrack" >> $TMPDIR/excludes
echo "videosnaps*" >> $TMPDIR/excludes
rsync -acviP --delete --log-file=$TMPDIR/mamelog.txt --exclude '*DS_Store*' --exclude-from=$TMPDIR/excludes $TMPDIR/downloads/mame0${mame_ver: -3}-64bit/ "$mame_dest"
rsync -aviP --delete --log-file=$TMPDIR/mamelog.txt --exclude '*.zip' "$TMPDIR/downloads/mame0${mame_ver: -3}-64bit/samples/" "$mame_dest/samples"

# Updating ROMs and CHDs
echo 'Updating ROMs and CHDs. This may take a while.' && sleep 2
mkdir -p "$mame_dest/roms"
rsync -aviP --delete --log-file=$TMPDIR/mamelog.txt --exclude '*_ReadMe_*' "$roms" "$chds" "$swlist_roms" "$swlist_chds" "$mame_dest/roms"

#Updating extras
echo 'Updating extras' && sleep 2
ls "$TMPDIR/downloads/mame0${mame_ver: -3}-64bit/" > $TMPDIR/excludes
cat << EOF >> $TMPDIR/excludes
_gsdata_
_ReadMe_.txt
.DS_Store
roms
artpreview*
bosses*
cabinets*
cheat*
covers_SL*
cpanel*
devices*
ends*
flyers*
gameover*
howto*
icons.zip
logo*
manuals*
marquees*
pcb*
scores*
select*
snap*
soundtrack
titles*
versus*
videosnaps*
warning*
EOF
rsync -aviP --delete --log-file=$TMPDIR/mamelog.txt --exclude-from=$TMPDIR/excludes "$extras/" "$mame_dest"
rm -r $TMPDIR/excludes

#SAMPLES
echo 'Updating samples' && sleep 2
rsync -acviP --delete --log-file=$TMPDIR/mamelog.txt --exclude '*DS_Store*' "$TMPDIR/downloads/mame0${mame_ver: -3}-64bit/samples/" "$extras/samples/" "$mame_dest/samples"

# Unzip/move EXTRAs zip files to destination
for zipfile in "$extras"/*.zip; do
  directory=$(echo $(basename "$zipfile" .zip))
  echo "Updating $directory" && sleep 2
  rm -rf "$TMPDIR/$directory"
  mkdir  "$TMPDIR/$directory"
  7za x -o$TMPDIR/$directory "$zipfile"
  if [[ $zipfile == *icons.zip ]]; then
    find $TMPDIR/icons/ -iname "*.ico" | xargs -L 1000 zip -0 $TMPDIR/icons.zip
    rsync -acviP --log-file=$TMPDIR/mamelog.txt --size-only $TMPDIR/icons.zip "$mame_dest/icons.zip"
    rm $TMPDIR/icons.zip
    rm -r $TMPDIR/icons
  else
    mkdir -p "$mame_dest/$directory"
    rsync -acviP --delete --log-file=$TMPDIR/mamelog.txt --exclude '*DS_Store*' "$TMPDIR/$directory/" "$mame_dest/$directory"
    rm -r "$TMPDIR/$directory"
  fi
done

#ARTWORK
echo 'Updating artwork' && sleep 2
mkdir $TMPDIR/artwork
cd "$extras/artwork"
for zipfile in *.zip; do
  exdir="${zipfile%.zip}"
  mkdir "$TMPDIR/artwork/$exdir" && 7za x -o"$TMPDIR/artwork/$exdir" "$zipfile"
done
rsync -acviP --delete --log-file=$TMPDIR/mamelog.txt --exclude '*DS_Store*' "$TMPDIR/downloads/mame0${mame_ver: -3}-64bit/artwork/" $TMPDIR/artwork/ "$mame_dest/artwork"
rm -r $TMPDIR/artwork

#CHEAT
echo 'Updating cheats' && sleep 2
mkdir $TMPDIR/cheat
7za x -o$TMPDIR/cheat "$extras/cheat.7z"
#zsh -c "touch -r **/*(om[1]) $TMPDIR/$cheat"
rsync -acviP --delete --log-file=$TMPDIR/mamelog.txt $TMPDIR/cheat/ "$mame_dest/cheat"
rm -r $TMPDIR/cheat

#VIDEOS
echo 'Updating videosnaps and soundtracks' && sleep 2
mkdir -p "$mame_dest/soundtrack" && rsync -aviP --delete --log-file=$TMPDIR/mamelog.txt "$multi/soundtrack/" "$mame_dest/soundtrack"
mkdir -p "$mame_dest/videosnaps" && rsync -aviP --delete --log-file=$TMPDIR/mamelog.txt "$multi/videosnaps/" "$mame_dest/videosnaps"
mkdir -p "$mame_dest/videosnaps_SL" && rsync -aviP --delete --log-file=$TMPDIR/mamelog.txt "$multi/videosnaps_SL/" "$mame_dest/videosnaps_SL"

#QMC2
read -p "MAME update complete. Install QMC2? (Y/N) " qmc
case $qmc in
  [Yy]* )
    #qmc_ver=`echo "$mame_ver 10 1.2" | awk '{printf "%.2f", $1 * $2 - $3}'`;
    cd $TMPDIR/downloads
    curl -LO http://downloads.sourceforge.net/project/qmc2/qmc2/$mame_ver/qmc2-macosx-intel-$mame_ver.dmg;
    hdiutil attach $TMPDIR/downloads/qmc2-macosx-intel-$mame_ver.dmg;
    open /Volumes/QMC2-$mame_ver/QMC2.mpkg;
    read -rsp $'Press any key when installation is complete...\n' -n1 key;;
  [Nn]* )
    ;;
esac

#Cleanup
cd $cwd
if [ -d /Volumes/QMC2-$mame_ver ]; then hdiutil detach /Volumes/QMC2-$mame_ver; fi
rm -r $TMPDIR/downloads
echo 'Script complete!'
exit
