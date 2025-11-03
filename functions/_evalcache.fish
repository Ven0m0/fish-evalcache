function _evalcache
  test (count $argv) -eq 0; and return
  test -z "$FISH_EVALCACHE_DIR"; and set -gx FISH_EVALCACHE_DIR "$HOME/.fish-evalcache"
  set -l cmd (string split -m1 / $argv[1])[-1]
  set -l cmdHash noHash
  if command -sq md5sum
    set cmdHash (string join -- \n $argv | md5sum | string split -f1 ' ')
  else if command -sq md5
    set cmdHash (string join -- \n $argv | md5)
  end
  set -l cacheFile "$FISH_EVALCACHE_DIR/init-$cmd-$cmdHash.fish"
  # Reentrancy guard: if we're already generating a cache, don't recurse - just run the command.
  if set -q __EVALCACHE_RUNNING
    command $argv
    return $status
  end
  # If disabled, just run and source (if appropriate) — preserve previous behavior but not caching.
  if test "$FISH_EVALCACHE_DISABLE" = true
    command $argv | source
    return $status
  end
  # If cache exists, source it.
  if test -s "$cacheFile"
    source "$cacheFile"
    return $status
  end
  # Ensure command exists.
  if not type -q -- $argv[1]
    echo "evalcache ERROR: command '$argv[1]' not found" >&2
    return 1
  end
  echo "$argv[1] init not cached, caching: $argv" >&2
  mkdir -p "$FISH_EVALCACHE_DIR"
  # remove previous cache files quietly
  rm -f $FISH_EVALCACHE_DIR/init-$cmd-*.fish 2>/dev/null
  # mark we are generating to avoid recursion
  set -gx __EVALCACHE_RUNNING 1
  # Run the command via `command` (avoid function/alias shadowing). Capture stdout/stderr into cacheFile.
  # On success + non-empty output -> source it. Otherwise remove cache and report error.
  if command $argv >"$cacheFile" 2>&1
    set -l stat $status
    if test $stat -eq 0 -a -s "$cacheFile"
      set -e __EVALCACHE_RUNNING
      source "$cacheFile"
      return 0
    else
      echo "evalcache ERROR: '$argv[1]' init produced empty output or non-zero status ($stat)" >&2
      rm -f "$cacheFile"
      set -e __EVALCACHE_RUNNING
      return $stat
    end
  else
    set -l stat $status
    echo "evalcache ERROR: '$argv[1]' init failed (status $stat)" >&2
    rm -f "$cacheFile"
    set -e __EVALCACHE_RUNNING
    return $stat
  end
end
