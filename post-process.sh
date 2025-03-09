#!/usr/bin/env bash

# Credit for this script from https://github.com/Protektor-Desura/jellyfin-dvr-comskip/tree/main, modified slightly

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set ffmpeg path to Jellyfin ffmpeg
__ffmpeg="$(which ffmpeg || echo '/usr/lib/jellyfin-ffmpeg/ffmpeg')"

# Set to skip commercials (mark as chapters) or cut commercials
__command="$(pwd)/comcut"

__comskipini="$(pwd)/comskip.ini"

# Set video codec for ffmpeg
__videocodec="libvpx-vp9"

# Set audio codec for ffmpeg
__audiocodec="libopus"

# Set bitrate for audio codec for ffmpeg
__bitrate="128000"

# Set video container
__container="mkv"

# Set CRF
__crf="20"

# Set Preset
__preset="slow"

# Green Color
GREEN='\033[0;32m'

# No Color
NC='\033[0m'

# Set Path
__path="${1:-}"

PWD="$(pwd)"

die () {
    echo >&2 "$@"
    cd "${PWD}"
    exit 1
}

# Verify a path was provided
[ -n "$__path" ] || die "path is required"
# Verify the path exists
[ -f "$__path" ] || die "path ($__path) is not a file"

__dir="$(dirname "${__path}")"
__file="$(basename "${__path}")"
__base="$(basename "${__path}" ".ts")"

# Debugging path variables
printf "${GREEN}path:${NC} ${__path}\ndir: ${__dir}\nbase: ${__base}\n"

# Change to the directory containing the recording
cd "${__dir}"

# Extract closed captions to external SRT file
printf "[post-process.sh] %bExtracting subtitles...%b\n" "$GREEN" "$NC"
#$__ffmpeg -f lavfi -i movie="${__file}[out+subcc]" -map 0:1 "${__base}.en.srt"

# Run comcut/comskip inside the container
echo "Running Comcut with the following command:"
echo "$__command --ffmpeg=$__ffmpeg --work-dir=\"${__dir}\" --comskip=/usr/bin/comskip --lockfile=/tmp/comchap.lock --comskip-ini=\"${__comskipini}\" \"${__file}\""
$__command --ffmpeg=$__ffmpeg --work-dir="$__dir" --comskip=/usr/bin/comskip --lockfile=/tmp/comchap.lock --comskip-ini="${__comskipini}" "${__file}"

# Transcode to mkv, crf parameter can be adjusted to change output quality
printf "[post-process.sh] %bTranscoding file...%b\n" "$GREEN" "$NC"
$__ffmpeg -i "${__file}" "${__base}.${__container}"

# Remove the original recording file
printf "[post-process.sh] %bRemoving original file...%b\n" "$GREEN" "$NC"
rm "${__file}"

# Return to the starting directory
cd "${PWD}"
