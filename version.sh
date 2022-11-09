#!/bin/bash
##################################################################
# versions.sh
# Generate a csv files with alpine-friendly versions
# for RUBY_VERSION and NODE_VERSION, for every released of decidim.
#
# ```
# DOCKERHUB_PERSONAL_TOKEN=<token> version.sh 1>&2
# ```
# Where `DOCKERHUB_PERSONAL_TOKEN` is a dockerhub token to 
# increase access limits.
#
# Requirement
# 
# Output
# ===
# A csv file with: 
# decidim version | decidim major version (ex. 24) | decidim minor version (ex. 3) | node version | ruby version | bundler version
# 
# FIXME: this script should run in a github action.
##################################################################
set -e

echo "Running version.sh"
echo "" > ./node_versions.txt
echo "" > ./versions.csv

gemfiles=$(gem list decidim-generators --remote --all --no-details | grep -o -E '[0-9\.0-9\.0-9]+')
major_version=""
minor_version=""
ruby_versions=()
node_versions=()
decidim_versions=()
i=1

# Get all the alpine node images.
node_count=$(curl --silent \
		-H 'Accept: application/json' \
		-H "Authorization: Bearer $DOCKERHUB_PERSONAL_TOKEN" \
								-H 'Content-Type: application/json' \
		"https://hub.docker.com/v2/namespaces/library/repositories/node/tags?page=$i&page_size=100" | jq ".count")
node_pages=$(($node_count / 100 + 1))
echo -n "Retrieve alpine nodes ($node_count)"
until [ $i -gt $node_pages ]; do
	query=$(curl --silent \
			-H 'Accept: application/json' \
			-H "Authorization: Bearer $DOCKERHUB_PERSONAL_TOKEN" \
									-H 'Content-Type: application/json' \
			"https://hub.docker.com/v2/namespaces/library/repositories/node/tags?page=$i&page_size=100")
	if [[ `echo $query | jq ".next"` ]]; then
		node_versions+=$(echo $query | jq ".results[].name")
	fi
  echo -n "."
	((i=i+1))
done
echo ""
echo "$node_versions" | grep alpine > node_versions.txt

i=1
ruby_count=$(curl --silent \
		-H 'Accept: application/json' \
		-H "Authorization: Bearer $DOCKERHUB_PERSONAL_TOKEN" \
								-H 'Content-Type: application/json' \
		"https://hub.docker.com/v2/namespaces/library/repositories/ruby/tags?page=$i&page_size=100" | jq ".count")
ruby_pages=$(($ruby_count / 100 + 1))
echo -n "Retrieve alpine ruby ($ruby_count)"
until [ $i -gt $ruby_pages ]; do
	query=$(curl --silent \
			-H 'Accept: application/json' \
			-H "Authorization: Bearer $DOCKERHUB_PERSONAL_TOKEN" \
									-H 'Content-Type: application/json' \
			"https://hub.docker.com/v2/namespaces/library/repositories/ruby/tags?page=$i&page_size=100")
	if [[ `echo $query | jq ".next"` ]]; then
		ruby_versions+=$(echo $query | jq ".results[].name")
	fi
  echo -n "."
	((i=i+1))
done
echo ""
echo "$ruby_versions" | grep alpine3.15 > ruby_versions.txt

# Foreach decidim version, grap the required node and ruby version
# We consider only the last available minor version (0.24.2 will be discarded)
for generator_version in $gemfiles; do
	new_major_version=$(echo "$generator_version" | cut -d'.' -f 1)
	new_minor_version=$(echo "$generator_version" | cut -d'.' -f 2)
	if [ "${major_version}" != "${new_major_version}" ] || [ "${minor_version}" != "${new_minor_version}" ]; then

		echo "Pick node,ruby version for decidim-$generator_version"
		decidim_node=$(curl --silent -f -lSL "https://raw.githubusercontent.com/decidim/decidim/release/${new_major_version}.${new_minor_version}-stable/package.json" | jq '.engines.node' | grep -o -E '[0-9\.0-9\.0-9]+')
		decidim_ruby=$(curl --silent -f -lSL "https://raw.githubusercontent.com/decidim/decidim/release/$new_major_version.$new_minor_version-stable/.ruby-version" | grep -o -E '[0-9\.0-9\.0-9]+')
		# decrease node patch version until having a match with an available alpine image
		picked_node_version=$decidim_node
		major_node=$(echo "$picked_node_version" | cut -d'.' -f 1)
		minor_node=$(echo "$picked_node_version" | cut -d'.' -f 2)
		patch_node=$(echo "$picked_node_version" | cut -d'.' -f 3)
		echo "	check node:$picked_node_version-alpine"
		until [[ `grep -wic "$picked_node_version-alpine" node_versions.txt` -gt 0 ]]
		do
			if [[ "$patch_node" -eq "-1" ]]; then
				# We can't find any alpine image for this decidim version, not available on docker. 
				picked_node_version="ERROR"
				break
			fi;
			echo -n "node:$picked_node_version-alpine not found."
			patch_node=$(($patch_node - 1))
			if [[ "$patch_node" -eq "-1" ]]; then
				picked_node_version="$major_node.$minor_node"
			else
				picked_node_version="$major_node.$minor_node.$patch_node"
			fi
			echo " Check node:$picked_node_version-alpine"
		done
		echo "	Picked Node: $picked_node_version"
		# decrease ruby patch version until having a match with an available alpine image
		picked_ruby_version=$decidim_ruby
		major_ruby=$(echo "$picked_ruby_version" | cut -d'.' -f 1)
		minor_ruby=$(echo "$picked_ruby_version" | cut -d'.' -f 2)
		patch_ruby=$(echo "$picked_ruby_version" | cut -d'.' -f 3)
		until [[ `grep -wic "$picked_ruby_version-alpine3.15" ruby_versions.txt` -gt 0 ]]
		do
			if [[ "$patch_ruby" -eq "-1" ]]; then
				# We can't find any alpine image for this decidim version, not available on docker. 
				picked_ruby_version="ERROR"
				break
			fi;
			echo -n "	ruby:$picked_ruby_version-alpine3.15 not found."
			patch_ruby=$(($patch_ruby - 1))
			if [[ "$patch_ruby" -eq "-1" ]]; then
				# Last try, try to get rid of the patch version
				picked_ruby_version="$major_ruby.$minor_ruby"
			else
				picked_ruby_version="$major_ruby.$minor_ruby.$patch_ruby"
			fi
			echo " Check ruby:$picked_ruby_version-alpine3.15"
		done
		echo "	Picked Ruby: $picked_ruby_version"
		bundler_version="-"
		if [[ "$picked_ruby_version" != "ERROR" ]]; then
			bundler_version=$(gem list bundler -e -r -v $picked_ruby_version | tail -1 | sed 's/.*(\(.*\)).*/\1/')
		fi
		decidim_versions+="$generator_version;$new_major_version;$new_minor_version;$picked_node_version;$picked_ruby_version;$bundler_version\n"
		major_version="$new_major_version"
		minor_version="$new_minor_version"
    echo -n "."
	fi
done 
echo -e $decidim_versions > versions.csv;
rm node_versions.txt;
rm ruby_versions.txt;

echo -e "\ndone! Happy CI/CD :)"
echo -e "\ndecidim version;decidim major version (ex. 24);decidim minor version (ex. 3);node version;ruby version;bundler version"
cat versions.csv