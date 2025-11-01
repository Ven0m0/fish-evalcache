function _evalcache_clear
  test -z "$FISH_EVALCACHE_DIR"; and set -gx FISH_EVALCACHE_DIR "$HOME/.fish-evalcache"
  if test (count $argv) -eq 0
    rm -i "$FISH_EVALCACHE_DIR"/init-*.fish
  else
    set -l cmd (string split -m1 / $argv[1])[-1]
    rm -i "$FISH_EVALCACHE_DIR/init-$cmd"-*.fish
  end
end
