{ ... }:

#############################################################
#
#  Keyboard Configuration
#
#  键盘相关的设置全部集中在这里（原来 system-defaults.nix 里的
#  KeyRepeat 也挪了过来），避免 nix-darwin 和 home-manager 两边
#  同时往 NSGlobalDomain 写同一个键、谁后跑谁生效。
#
#  没有做 hidutil 键位重映射（`hidutil property --get UserKeyMapping`
#  全是 null），所以用不到 nix-darwin 的 system.keyboard.userKeyMapping。
#
#############################################################

{
  targets.darwin.defaults = {
    NSGlobalDomain = {
      # 按键重复：设置 > 键盘
      KeyRepeat = 2;         # 重复速度（越小越快）
      InitialKeyRepeat = 15; # 重复前延迟

      # 文本 > 拼写与替换
      NSAutomaticCapitalizationEnabled = true;      # 自动大写
      NSAutomaticPeriodSubstitutionEnabled = true;  # 双击空格加句号
      NSAllowContinuousSpellChecking = false;       # 关掉边输入边拼写检查
      KB_SpellingLanguage.KB_SpellingLanguageIsAutomatic = true;

      # 智能引号
      KB_DoubleQuoteOption = "“abc”";
      KB_SingleQuoteOption = "‘abc’";
      NSUserQuotesArray = [ "“" "”" "‘" "’" ];

      # 文本替换
      # "with" 是 Nix 关键字，属性名必须加引号
      NSUserDictionaryReplacementItems = [
        { on = 1; replace = "omw"; "with" = "On my way!"; }
        { on = 1; replace = "msd"; "with" = "马上到！"; }
      ];
    };

    # 输入法。AppleEnabledInputSources 是"设置 > 键盘 > 输入法"里的完整
    # 列表；当前选中项（AppleSelectedInputSources /
    # AppleCurrentKeyboardLayoutInputSourceID）和 AppleInputSourceHistory
    # 是运行时状态，随时在变，不同步。
    "com.apple.HIToolbox" = {
      AppleDictationAutoEnable = 1;

    # 注意：这个数组是有序的，顺序就是输入法的切换顺序，别按语言重排。
      AppleEnabledInputSources = [
        # 繁体拼音
        {
          "Bundle ID" = "com.apple.inputmethod.TCIM";
          "Input Mode" = "com.apple.inputmethod.TCIM.Pinyin";
          InputSourceKind = "Input Mode";
        }
        # 美式键盘
        {
          InputSourceKind = "Keyboard Layout";
          "KeyboardLayout ID" = 0;
          "KeyboardLayout Name" = "U.S.";
        }
        # 简体拼音
        {
          "Bundle ID" = "com.apple.inputmethod.SCIM";
          "Input Mode" = "com.apple.inputmethod.SCIM.ITABC";
          InputSourceKind = "Input Mode";
        }
        {
          "Bundle ID" = "com.apple.inputmethod.TCIM";
          InputSourceKind = "Keyboard Input Method";
        }
        # 日语罗马字
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
        # Colemak 布局
        {
          InputSourceKind = "Keyboard Layout";
          "KeyboardLayout ID" = 12825;
          "KeyboardLayout Name" = "Colemak";
        }

        # 非键盘输入法（表情与符号、手写等，系统默认带的）
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
