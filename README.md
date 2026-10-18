## Zamorak Bad Luck Tracker

This plugin is designed for use at Zamorak, Lord of Chaos in order to automatically track the Bad Luck Mitigation (BLM) drop mechanic associated with him.

Once you have killed him 10 times at 100% enrage or higher without a unique drop, you will start accumulating BLM value which will decrease the denominator of the drop chance.

For further information regarding the BLM mechanics see the wiki: https://runescape.wiki/w/Zamorak,_Lord_of_Chaos#Bad_luck_mitigation

### Features
The plugin centres around a Zamorak Bad Luck info box, designed to mimic the Slayer counter interface. The info box is only visible while within ED4 or outside the entrance of ED4. It can be compacted/expanded in a toggle fashion by clicking the gold Zamorak icon. The direction it resizes in can be changed in the settings. The info box can also be moved identically to any other native interface, by unlocking your interface and dragging it to your preferred location.

[!Example of the info box.](/resources/images/InfoBox.png)

While the info box is expanded, the dry streak and unique chance are visible.
- The dry streak increasing each time the treasure chest is looted above 100% enrage without a unique dropping.
- The unique chance is calculated based on an accumulating "bad luck mitigation" value and your current enrage.

If the 'Toggle chance display' option is set to either 'Click' or 'Hover', you can interact in the corresponding way with the 'Unique chance' row in order to toggle the format of the information being displayed.

[!A demo of the interactive elements of the info box.](/resources/images/Demo.gif)

Clicking on the golden Zamorak icon will either shrink or expand the info box. While in this compacted state the Unique chance is displayed and when hovered the dry streak is displayed as a tooltip.

### Settings
The settings can be accessed through the Plugin menu.

- Compact direction: The corner of the info box which the interface will compact towards.
- Unique chance display: The format the unique chance is displayed, either as a percentage or a fraction.
- Toggle chance display: Allows a quick method for swapping the Unique chance display between percentage and fraction.

### Credits
Plugin by Ceren and thanks to J3 for their work on PrettyUI.