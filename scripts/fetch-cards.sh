#!/usr/bin/env bash
# Downloads every image the profile README shows and saves it under profile/,
# so GitHub serves finished SVGs from this repo instead of rendering them on
# each view. The live endpoints (Vercel cold starts) are often slower than
# GitHub's image proxy waits, which is why cards used to need a refresh.
#
#   DYNAMIC  re-fetched on every run (stats change).
#   STATIC   fetched only when the file is missing, or with REFRESH_STATIC=1.
#
# profile/typing-footer.svg is not listed: it came from readme-typing-svg but
# its <animate> was retimed by hand to pause after "You made it to the end!",
# which the generator cannot do. Its embedded font is a subset holding only
# that sentence's characters, so new text with other letters needs a fresh
# download from the generator, then the same retiming.
#
# An entry may name a third field: a local SVG that replaces the badge's logo.
# Shields only knows Simple Icons, which has no Pelican Panel or Code - OSS
# logo, so those badges are requested with a stand-in logo (same layout) and
# then swapped.
#
# Every image also has a light-theme twin (x-light.svg) that the README
# serves through <picture> to visitors on GitHub's light theme. Cards and the
# header list theirs explicitly; each shields badge gets one derived by
# light_url, which mirrors the grey ramp (#vv -> #(0x110 - vv), so ffffff ->
# 111111, 555555 -> bbbbbb) and swaps the logo between black and white. A
# custom logo has a twin too: logos/x-light.svg.
#
# A response that is not an SVG, or looks like a card's error message, never
# overwrites the committed file; the script exits non-zero instead.
set -euo pipefail

cd "$(dirname "$0")/.."

DYNAMIC=(
  "profile/stats.svg|https://stats.arqone.eu/api?username=kexe-dev&count_private=true&include_all_commits=true&show_icons=true&theme=dark&hide_border=true&bg_color=0d1117&title_color=ffffff&icon_color=aaaaaa&text_color=bbbbbb"
  "profile/stats-light.svg|https://stats.arqone.eu/api?username=kexe-dev&count_private=true&include_all_commits=true&show_icons=true&theme=default&hide_border=true&bg_color=ffffff&title_color=111111&icon_color=666666&text_color=555555"
  "profile/streak.svg|https://streakstats.arqone.eu/api?user=kexe-dev&theme=dark&hide_border=true&background=0d1117&ring=FF6600&fire=FF4500&currStreakLabel=ffffff&sideLabels=aaaaaa&dates=666666"
  "profile/streak-light.svg|https://streakstats.arqone.eu/api?user=kexe-dev&theme=default&hide_border=true&background=ffffff&ring=FF6600&fire=FF4500&currStreakNum=111111&sideNums=111111&currStreakLabel=111111&sideLabels=666666&dates=aaaaaa&stroke=2c2e2e"
  "profile/wakatime.svg|https://stats.arqone.eu/api/wakatime?username=kexe_dev&theme=dark&hide_border=true&bg_color=0d1117&title_color=ffffff&text_color=bbbbbb&layout=compact&v=1"
  "profile/wakatime-light.svg|https://stats.arqone.eu/api/wakatime?username=kexe_dev&theme=default&hide_border=true&bg_color=ffffff&title_color=111111&text_color=555555&layout=compact&v=1"
  "profile/graph.svg|https://graphstats.arqone.eu/graph?username=kexe-dev&theme=react-dark&bg_color=0d1117&color=ffffff&line=555555&point=aaaaaa&hide_border=true&area=true&area_color=222222"
  "profile/graph-light.svg|https://graphstats.arqone.eu/graph?username=kexe-dev&bg_color=ffffff&color=111111&title_color=111111&line=bbbbbb&point=666666&hide_border=true&area=true&area_color=eeeeee"
)

STATIC=(
  "profile/typing-header.svg|https://readme-typing-svg.demolab.com?font=Fira+Code&weight=700&size=28&duration=2000&pause=1000&color=FFFFFF&center=true&vCenter=true&width=800&lines=Alexander+Miroslav+Milan;AI+Student;Networks+%7C+Cybersecurity+%7C+Self-hosting;Building+arqone.eu"
  "profile/typing-header-light.svg|https://readme-typing-svg.demolab.com?font=Fira+Code&weight=700&size=28&duration=2000&pause=1000&color=111111&center=true&vCenter=true&width=800&lines=Alexander+Miroslav+Milan;AI+Student;Networks+%7C+Cybersecurity+%7C+Self-hosting;Building+arqone.eu"
  "profile/badges/ko-fi.svg|https://img.shields.io/badge/Ko--fi-Support%20me-white?style=for-the-badge&logo=ko-fi&logoColor=black"
  "profile/badges/os-arch-linux.svg|https://img.shields.io/badge/OS-Arch_Linux-ffffff?style=for-the-badge&logo=arch-linux&logoColor=black"
  "profile/badges/website.svg|https://img.shields.io/badge/arqone.eu-dddddd?style=for-the-badge&logo=firefox&logoColor=black"
  "profile/badges/instagram.svg|https://img.shields.io/badge/Instagram-aaaaaa?style=for-the-badge&logo=instagram&logoColor=black"
  "profile/badges/discord.svg|https://img.shields.io/badge/Discord-666666?style=for-the-badge&logo=discord&logoColor=white"
  "profile/badges/python.svg|https://img.shields.io/badge/Python-ffffff?style=for-the-badge&logo=python&logoColor=black"
  "profile/badges/html5.svg|https://img.shields.io/badge/HTML5-dddddd?style=for-the-badge&logo=html5&logoColor=black"
  "profile/badges/css3.svg|https://img.shields.io/badge/CSS3-bbbbbb?style=for-the-badge&logo=css&logoColor=black"
  "profile/badges/bash.svg|https://img.shields.io/badge/Bash-999999?style=for-the-badge&logo=gnubash&logoColor=black"
  "profile/badges/cisco.svg|https://img.shields.io/badge/Cisco-ffffff?style=for-the-badge&logo=cisco&logoColor=black"
  "profile/badges/linux.svg|https://img.shields.io/badge/Linux-dddddd?style=for-the-badge&logo=linux&logoColor=black"
  "profile/badges/arch-linux.svg|https://img.shields.io/badge/Arch_Linux-bbbbbb?style=for-the-badge&logo=arch-linux&logoColor=black"
  "profile/badges/nginx.svg|https://img.shields.io/badge/Nginx-999999?style=for-the-badge&logo=nginx&logoColor=black"
  "profile/badges/cloudflare.svg|https://img.shields.io/badge/Cloudflare-777777?style=for-the-badge&logo=cloudflare&logoColor=white"
  "profile/badges/wireguard.svg|https://img.shields.io/badge/WireGuard-555555?style=for-the-badge&logo=wireguard&logoColor=white"
  "profile/badges/ubuntu.svg|https://img.shields.io/badge/Ubuntu-ffffff?style=for-the-badge&logo=ubuntu&logoColor=black"
  "profile/badges/raspberry-pi.svg|https://img.shields.io/badge/Raspberry_Pi-dddddd?style=for-the-badge&logo=raspberrypi&logoColor=black"
  "profile/badges/tailscale.svg|https://img.shields.io/badge/Tailscale-bbbbbb?style=for-the-badge&logo=tailscale&logoColor=black"
  "profile/badges/git.svg|https://img.shields.io/badge/Git-ffffff?style=for-the-badge&logo=git&logoColor=black"
  "profile/badges/code-oss.svg|https://img.shields.io/badge/Code_--_OSS-dddddd?style=for-the-badge&logo=vscodium&logoColor=black|profile/logos/code-oss.svg"
  "profile/badges/pelican.svg|https://img.shields.io/badge/Pelican-bbbbbb?style=for-the-badge&logo=pelican&logoColor=black|profile/logos/pelican.svg"
  "profile/badges/ollama.svg|https://img.shields.io/badge/Ollama-999999?style=for-the-badge&logo=ollama&logoColor=white"
  "profile/badges/arduino.svg|https://img.shields.io/badge/Arduino-777777?style=for-the-badge&logo=arduino&logoColor=white"
  "profile/badges/fusion-360.svg|https://img.shields.io/badge/Fusion_360-555555?style=for-the-badge&logo=autodesk&logoColor=white"
)

# Text the cards render instead of data when something upstream fails
# (bad token, rate limit, unknown user). They usually still answer 200.
ERROR_PATTERN='Something went wrong|Could not (fetch|find|resolve)|Can.t fetch|rate limit|Bad credentials|User not found|Maximum retries'

failed=0

fetch() {
  local out=$1 url=$2 logo=${3:-} tmp
  tmp=$(mktemp)
  if ! curl -fsSL --retry 4 --retry-all-errors --retry-delay 5 --max-time 60 \
      -A 'kexe-dev-profile-cards' -o "$tmp" "$url"; then
    echo "::error::$out: request failed"
    rm -f "$tmp"; failed=1; return
  fi
  # The streak-stats deployment runs a PHP that prints deprecation notices
  # ahead of the SVG on a cold start. That output also stops it setting its
  # headers, so the live URL serves text/html junk and the image breaks
  # until a warm instance answers. Strip that prefix, but say so: the real
  # fix is display_errors=Off in the streak-stats fork.
  local before after
  before=$(wc -c < "$tmp")
  perl -0777 -i -pe 's{\A(?:\s*<br />\s*<b>(?:Deprecated|Warning|Notice)</b>:.*?<br />)+\s*}{}s' "$tmp"
  after=$(wc -c < "$tmp")
  if (( after != before )); then
    echo "::warning::$out: stripped $((before - after)) bytes of PHP notices printed before the SVG"
  fi
  if ! perl -0777 -ne 'exit(/\A\s*(?:<\?xml[^>]*>\s*)?(?:<!--.*?-->\s*)*<svg[\s>]/s ? 0 : 1)' "$tmp"; then
    echo "::error::$out: response is not an SVG"
    rm -f "$tmp"; failed=1; return
  fi
  if grep -Eqi "$ERROR_PATTERN" "$tmp"; then
    echo "::error::$out: card contains an error message ($(grep -Eoi "$ERROR_PATTERN" "$tmp" | head -1))"
    rm -f "$tmp"; failed=1; return
  fi
  # GitHub renders README images in a sandbox that blocks outside loads, so
  # an SVG pulling in a remote font or image would not look the same.
  if grep -Eq '@import|url\(["'\'']?https?:|<image[^>]+href="https?:' "$tmp"; then
    echo "::error::$out: SVG references an external resource and would render differently"
    rm -f "$tmp"; failed=1; return
  fi
  if [[ -n $logo ]]; then
    local b64
    b64=$(base64 -w0 "$logo")
    perl -0777 -i -pe "s{(<image [^>]*href=\")data:image/svg\+xml;base64,[^\"]*}{\$1data:image/svg+xml;base64,$b64}" "$tmp"
    if ! grep -qF "$b64" "$tmp"; then
      echo "::error::$out: could not swap in the logo from $logo"
      rm -f "$tmp"; failed=1; return
    fi
  fi
  mkdir -p "$(dirname "$out")"
  mv "$tmp" "$out"
  chmod 644 "$out"
  echo "ok  $out"
}

light_url() {
  local url=$1 color v shade
  color=$(sed -nE 's#.*-([0-9a-fA-F]{6}|white)\?style=.*#\1#p' <<< "$url")
  [[ $color == white ]] && color=ffffff
  color=${color,,}
  if [[ ${#color} != 6 || ${color:0:2} != "${color:2:2}" || ${color:2:2} != "${color:4:2}" ]]; then
    echo "::error::light_url: $url is not a grey badge" >&2
    return 1
  fi
  v=$((16#${color:0:2}))
  shade=$(printf '%02x' $((0x110 - v)))
  url=$(sed -E "s#-([0-9a-fA-F]{6}|white)\?style=#-$shade$shade$shade?style=#" <<< "$url")
  case $url in
    *logoColor=black*) url=${url/logoColor=black/logoColor=white} ;;
    *logoColor=white*) url=${url/logoColor=white/logoColor=black} ;;
  esac
  echo "$url"
}

if [[ ${1:-} == --print-light ]]; then
  for entry in "${STATIC[@]}"; do
    IFS='|' read -r out url logo <<< "$entry"
    [[ $url == https://img.shields.io/badge/* ]] && echo "${out%.svg}-light.svg  $(light_url "$url")"
  done
  exit 0
fi

for entry in "${DYNAMIC[@]}"; do
  IFS='|' read -r out url logo <<< "$entry"
  fetch "$out" "$url" "$logo"
done

fetch_static() {
  if [[ -f $1 && ${REFRESH_STATIC:-0} != 1 ]]; then
    return
  fi
  fetch "$@"
}

for entry in "${STATIC[@]}"; do
  IFS='|' read -r out url logo <<< "$entry"
  fetch_static "$out" "$url" "$logo"
  if [[ $url == https://img.shields.io/badge/* ]]; then
    fetch_static "${out%.svg}-light.svg" "$(light_url "$url")" "${logo:+${logo%.svg}-light.svg}"
  fi
done

exit "$failed"
