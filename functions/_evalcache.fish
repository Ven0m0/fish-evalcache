function _evalcache
  test (count $argv) -eq 0; and return
  test -z "$FISH_EVALCACHE_DIR"; and set -gx FISH_EVALCACHE_DIR "$HOME/.fish-evalcache"
  set -l cmd (string split -m1 / $argv[1])[-1]
  set -l cmdHash noHash
  if command -sq md5sum
    set cmdHash (string join \n $argv | md5sum | string split -f1 ' ')
  else if command -sq md5
    set cmdHash (string join \n $argv | md5)
  end
  set -l cacheFile "$FISH_EVALCACHE_DIR/init-$cmd-$cmdHash.fish"
  if test "$FISH_EVALCACHE_DISABLE" = true
    eval ($argv | source)
  else if test -s "$cacheFile"
    source "$cacheFile"
  else if type -q $argv[1]
    echo "$argv[1] init not cached, caching: $argv" >&2
    mkdir -p "$FISH_EVALCACHE_DIR"
    rm -f "$FISH_EVALCACHE_DIR/init-$cmd-"*".fish"
    $argv >$cacheFile
    source "$cacheFile"
  else
    echo "evalcache ERROR: $cmd not in PATH" >&2
  end
end
