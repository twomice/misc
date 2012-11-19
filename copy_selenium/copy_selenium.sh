source ./copy_selenium_config.sh

# rsync all Selenium files
rsync -avP -f"- .hg" $rsync_source $rsync_target

# Change to the target directory.
cd $rsync_target

# loop through each file with a "onepager" setting
for source_file in `grep -l "<td>$varname</td>" ./*`
do

  # Get the line number of the onepager path setting value.
  line=`grep -n "<td>$varname</td>" $source_file | awk -F: '{print $1}'`;
  let "line-=1";

  # Update the file.
  filename=`tempfile`
  eval "sed -e \""$line"s/^.*$/<td>"$onepager_path"<\/td>/\"" $source_file > $filename
  cat $filename > $source_file
done
