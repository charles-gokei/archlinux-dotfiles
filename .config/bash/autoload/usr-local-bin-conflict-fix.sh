export PATH=$(echo $PATH | tr : \\n | sed -E 's/\/usr\/local\/s?bin//g' | sed '/^$/d' | tr \\n :)

