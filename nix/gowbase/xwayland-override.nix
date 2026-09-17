final: prev:
{
  cumulus-xwayland = prev.xwayland.overrideAttrs (old: {
    #  src = prev.xwayland.src.overrideAttrs(old: {
        postFetch = ''
            TARGET=hw/xwayland/xwayland-output.c
            ls -la "$TARGET"
            BEFORE=$(grep -c 'ARRAY_SIZE(xwl_output_fake_modes)' "$TARGET" || true)
            echo "BEFORE sentinel count: $BEFORE"
            test "$BEFORE" -ge 1 || { echo "Sentinel ARRAY_SIZE(xwl_output_fake_modes) not found in $TARGET — upstream structure may have changed, refresh the patch."; exit 1; }
            sed -i 's/ARRAY_SIZE(xwl_output_fake_modes)/0/g' "$TARGET"
            AFTER=$(grep -c 'ARRAY_SIZE(xwl_output_fake_modes)' "$TARGET" || true)
            echo "AFTER sentinel count: $AFTER"
            test "$AFTER" -eq 0 || { echo "sed transformation incomplete (still $AFTER matches)"; exit 1; }
            echo "Neutralized $BEFORE fake-mode iteration site(s)"
        '';
       # version = prev.xwayland.version + "-cumulus";
   #   });
  });
}