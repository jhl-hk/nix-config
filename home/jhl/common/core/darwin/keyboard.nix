{...}:
#############################################################
#
#  Keyboard Configuration
#
#  All keyboard-related settings are collected here (KeyRepeat moved over from
#  system-defaults.nix), so that nix-darwin and home-manager don't both write
#  the same NSGlobalDomain key and leave the winner up to which ran last.
#
#  No hidutil key remapping is in use (`hidutil property --get UserKeyMapping`
#  is all null), so nix-darwin's system.keyboard.userKeyMapping is not needed.
#
#############################################################
{
  targets.darwin.defaults = {
    NSGlobalDomain = {
      # Key repeat: Settings > Keyboard
      KeyRepeat = 2; # repeat rate (lower is faster)
      InitialKeyRepeat = 15; # delay before repeating

      # Text > Spelling and substitution
      NSAutomaticCapitalizationEnabled = true; # auto-capitalize
      NSAutomaticPeriodSubstitutionEnabled = true; # double-space inserts a period
      NSAllowContinuousSpellChecking = false; # no spell-check while typing
      KB_SpellingLanguage.KB_SpellingLanguageIsAutomatic = true;

      # Smart quotes
      KB_DoubleQuoteOption = "“abc”";
      KB_SingleQuoteOption = "‘abc’";
      NSUserQuotesArray = ["“" "”" "‘" "’"];

      # Text replacements
      # "with" is a Nix keyword, so the attribute name must be quoted
      NSUserDictionaryReplacementItems = [
        {
          on = 1;
          replace = "omw";
          "with" = "On my way!";
        }
        {
          on = 1;
          replace = "msd";
          "with" = "马上到！";
        }
      ];
    };

    # Input sources. AppleEnabledInputSources is the full list under
    # "Settings > Keyboard > Input Sources". The current selection
    # (AppleSelectedInputSources / AppleCurrentKeyboardLayoutInputSourceID) and
    # AppleInputSourceHistory are runtime state that changes constantly and is
    # deliberately not synced.
    "com.apple.HIToolbox" = {
      AppleDictationAutoEnable = 1;

      # Note: this array is ordered, and the order is the input-source cycling
      # order -- do not reshuffle it by language.
      AppleEnabledInputSources = [
        # Traditional Chinese Pinyin
        {
          "Bundle ID" = "com.apple.inputmethod.TCIM";
          "Input Mode" = "com.apple.inputmethod.TCIM.Pinyin";
          InputSourceKind = "Input Mode";
        }
        # U.S. keyboard
        {
          InputSourceKind = "Keyboard Layout";
          "KeyboardLayout ID" = 0;
          "KeyboardLayout Name" = "U.S.";
        }
        # Simplified Chinese Pinyin
        {
          "Bundle ID" = "com.apple.inputmethod.SCIM";
          "Input Mode" = "com.apple.inputmethod.SCIM.ITABC";
          InputSourceKind = "Input Mode";
        }
        {
          "Bundle ID" = "com.apple.inputmethod.TCIM";
          InputSourceKind = "Keyboard Input Method";
        }
        # Japanese Romaji
        {
          "Bundle ID" = "com.apple.inputmethod.Kotoeri.RomajiTyping";
          "Input Mode" = "com.apple.inputmethod.Japanese";
          InputSourceKind = "Input Mode";
        }
        {
          "Bundle ID" = "com.apple.inputmethod.Kotoeri.RomajiTyping";
          InputSourceKind = "Keyboard Input Method";
        }
        {
          "Bundle ID" = "com.apple.inputmethod.SCIM";
          InputSourceKind = "Keyboard Input Method";
        }
        # Colemak layout
        {
          InputSourceKind = "Keyboard Layout";
          "KeyboardLayout ID" = 12825;
          "KeyboardLayout Name" = "Colemak";
        }

        # Non-keyboard input methods (Emoji & Symbols, handwriting, etc. --
        # these ship with the system)
        {
          "Bundle ID" = "com.apple.CharacterPaletteIM";
          InputSourceKind = "Non Keyboard Input Method";
        }
        {
          "Bundle ID" = "com.apple.50onPaletteIM";
          InputSourceKind = "Non Keyboard Input Method";
        }
        {
          "Bundle ID" = "com.apple.PressAndHold";
          InputSourceKind = "Non Keyboard Input Method";
        }
        {
          "Bundle ID" = "com.apple.inputmethod.ironwood";
          InputSourceKind = "Non Keyboard Input Method";
        }
      ];
    };
  };
}
