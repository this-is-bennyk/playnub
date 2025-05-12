# MIT License
# 
# Copyright (c) 2025 Ben Kurtin
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

@tool
class_name ColorBoxFiller
extends BoxFiller

## Fills the associated [Box] with a [Color].

## All the named color constants from [Color].
const NAMED_COLORS_LIST: Array[Color] = [
	Color.ALICE_BLUE,
	Color.ANTIQUE_WHITE,
	Color.AQUA,
	Color.AQUAMARINE,
	Color.AZURE,
	Color.BEIGE,
	Color.BISQUE,
	Color.BLACK,
	Color.BLANCHED_ALMOND,
	Color.BLUE,
	Color.BLUE_VIOLET,
	Color.BROWN,
	Color.BURLYWOOD,
	Color.CADET_BLUE,
	Color.CHARTREUSE,
	Color.CHOCOLATE,
	Color.CORAL,
	Color.CORNFLOWER_BLUE,
	Color.CORNSILK,
	Color.CRIMSON,
	Color.CYAN,
	Color.DARK_BLUE,
	Color.DARK_CYAN,
	Color.DARK_GOLDENROD,
	Color.DARK_GRAY,
	Color.DARK_GREEN,
	Color.DARK_KHAKI,
	Color.DARK_MAGENTA,
	Color.DARK_OLIVE_GREEN,
	Color.DARK_ORANGE,
	Color.DARK_ORCHID,
	Color.DARK_RED,
	Color.DARK_SALMON,
	Color.DARK_SEA_GREEN,
	Color.DARK_SLATE_BLUE,
	Color.DARK_SLATE_GRAY,
	Color.DARK_TURQUOISE,
	Color.DARK_VIOLET,
	Color.DEEP_PINK,
	Color.DEEP_SKY_BLUE,
	Color.DIM_GRAY,
	Color.DODGER_BLUE,
	Color.FIREBRICK,
	Color.FLORAL_WHITE,
	Color.FOREST_GREEN,
	Color.FUCHSIA,
	Color.GAINSBORO,
	Color.GHOST_WHITE,
	Color.GOLD,
	Color.GOLDENROD,
	Color.GRAY,
	Color.GREEN,
	Color.GREEN_YELLOW,
	Color.HONEYDEW,
	Color.HOT_PINK,
	Color.INDIAN_RED,
	Color.INDIGO,
	Color.IVORY,
	Color.KHAKI,
	Color.LAVENDER,
	Color.LAVENDER_BLUSH,
	Color.LAWN_GREEN,
	Color.LEMON_CHIFFON,
	Color.LIGHT_BLUE,
	Color.LIGHT_CORAL,
	Color.LIGHT_CYAN,
	Color.LIGHT_GOLDENROD,
	Color.LIGHT_GRAY,
	Color.LIGHT_GREEN,
	Color.LIGHT_PINK,
	Color.LIGHT_SALMON,
	Color.LIGHT_SEA_GREEN,
	Color.LIGHT_SKY_BLUE,
	Color.LIGHT_SLATE_GRAY,
	Color.LIGHT_STEEL_BLUE,
	Color.LIGHT_YELLOW,
	Color.LIME,
	Color.LIME_GREEN,
	Color.LINEN,
	Color.MAGENTA,
	Color.MAROON,
	Color.MEDIUM_AQUAMARINE,
	Color.MEDIUM_BLUE,
	Color.MEDIUM_ORCHID,
	Color.MEDIUM_PURPLE,
	Color.MEDIUM_SEA_GREEN,
	Color.MEDIUM_SLATE_BLUE,
	Color.MEDIUM_SPRING_GREEN,
	Color.MEDIUM_TURQUOISE,
	Color.MEDIUM_VIOLET_RED,
	Color.MIDNIGHT_BLUE,
	Color.MINT_CREAM,
	Color.MISTY_ROSE,
	Color.MOCCASIN,
	Color.NAVAJO_WHITE,
	Color.NAVY_BLUE,
	Color.OLD_LACE,
	Color.OLIVE,
	Color.OLIVE_DRAB,
	Color.ORANGE,
	Color.ORANGE_RED,
	Color.ORCHID,
	Color.PALE_GOLDENROD,
	Color.PALE_GREEN,
	Color.PALE_TURQUOISE,
	Color.PALE_VIOLET_RED,
	Color.PAPAYA_WHIP,
	Color.PEACH_PUFF,
	Color.PERU,
	Color.PINK,
	Color.PLUM,
	Color.POWDER_BLUE,
	Color.PURPLE,
	Color.REBECCA_PURPLE,
	Color.RED,
	Color.ROSY_BROWN,
	Color.ROYAL_BLUE,
	Color.SADDLE_BROWN,
	Color.SALMON,
	Color.SANDY_BROWN,
	Color.SEA_GREEN,
	Color.SEASHELL,
	Color.SIENNA,
	Color.SILVER,
	Color.SKY_BLUE,
	Color.SLATE_BLUE,
	Color.SLATE_GRAY,
	Color.SNOW,
	Color.SPRING_GREEN,
	Color.STEEL_BLUE,
	Color.TAN,
	Color.TEAL,
	Color.THISTLE,
	Color.TOMATO,
	Color.TRANSPARENT,
	Color.TURQUOISE,
	Color.VIOLET,
	Color.WEB_GRAY,
	Color.WEB_GREEN,
	Color.WEB_MAROON,
	Color.WEB_PURPLE,
	Color.WHEAT,
	Color.WHITE,
	Color.WHITE_SMOKE,
	Color.YELLOW,
	Color.YELLOW_GREEN,
]

## Enumeration of all the named color constants from [Color].
enum NamedColors
{
	## Alice blue color.
	ALICE_BLUE,
	## Antique white color.
	ANTIQUE_WHITE,
	## Aqua color.
	AQUA,
	## Aquamarine color.
	AQUAMARINE,
	## Azure color.
	AZURE,
	## Beige color.
	BEIGE,
	## Bisque color.
	BISQUE,
	## Black color. In GDScript, this is the default value of any color.
	BLACK,
	## Blanched almond color.
	BLANCHED_ALMOND,
	## Blue color.
	BLUE,
	## Blue violet color.
	BLUE_VIOLET,
	## Brown color.
	BROWN,
	## Burlywood color.
	BURLYWOOD,
	## Cadet blue color.
	CADET_BLUE,
	## Chartreuse color.
	CHARTREUSE,
	## Chocolate color.
	CHOCOLATE,
	## Coral color.
	CORAL,
	## Cornflower blue color.
	CORNFLOWER_BLUE,
	## Cornsilk color.
	CORNSILK,
	## Crimson color.
	CRIMSON,
	## Cyan color.
	CYAN,
	## Dark blue color.
	DARK_BLUE,
	## Dark cyan color.
	DARK_CYAN,
	## Dark goldenrod color.
	DARK_GOLDENROD,
	## Dark gray color.
	DARK_GRAY,
	## Dark green color.
	DARK_GREEN,
	## Dark khaki color.
	DARK_KHAKI,
	## Dark magenta color.
	DARK_MAGENTA,
	## Dark olive green color.
	DARK_OLIVE_GREEN,
	## Dark orange color.
	DARK_ORANGE,
	## Dark orchid color.
	DARK_ORCHID,
	## Dark red color.
	DARK_RED,
	## Dark salmon color.
	DARK_SALMON,
	## Dark sea green color.
	DARK_SEA_GREEN,
	## Dark slate blue color.
	DARK_SLATE_BLUE,
	## Dark slate gray color.
	DARK_SLATE_GRAY,
	## Dark turquoise color.
	DARK_TURQUOISE,
	## Dark violet color.
	DARK_VIOLET,
	## Deep pink color.
	DEEP_PINK,
	## Deep sky blue color.
	DEEP_SKY_BLUE,
	## Dim gray color.
	DIM_GRAY,
	## Dodger blue color.
	DODGER_BLUE,
	## Firebrick color.
	FIREBRICK,
	## Floral white color.
	FLORAL_WHITE,
	## Forest green color.
	FOREST_GREEN,
	## Fuchsia color.
	FUCHSIA,
	## Gainsboro color.
	GAINSBORO,
	## Ghost white color.
	GHOST_WHITE,
	## Gold color.
	GOLD,
	## Goldenrod color.
	GOLDENROD,
	## Gray color.
	GRAY,
	## Green color.
	GREEN,
	## Green yellow color.
	GREEN_YELLOW,
	## Honeydew color.
	HONEYDEW,
	## Hot pink color.
	HOT_PINK,
	## Indian red color.
	INDIAN_RED,
	## Indigo color.
	INDIGO,
	## Ivory color.
	IVORY,
	## Khaki color.
	KHAKI,
	## Lavender color.
	LAVENDER,
	## Lavender blush color.
	LAVENDER_BLUSH,
	## Lawn green color.
	LAWN_GREEN,
	## Lemon chiffon color.
	LEMON_CHIFFON,
	## Light blue color.
	LIGHT_BLUE,
	## Light coral color.
	LIGHT_CORAL,
	## Light cyan color.
	LIGHT_CYAN,
	## Light goldenrod color.
	LIGHT_GOLDENROD,
	## Light gray color.
	LIGHT_GRAY,
	## Light green color.
	LIGHT_GREEN,
	## Light pink color.
	LIGHT_PINK,
	## Light salmon color.
	LIGHT_SALMON,
	## Light sea green color.
	LIGHT_SEA_GREEN,
	## Light sky blue color.
	LIGHT_SKY_BLUE,
	## Light slate gray color.
	LIGHT_SLATE_GRAY,
	## Light steel blue color.
	LIGHT_STEEL_BLUE,
	## Light yellow color.
	LIGHT_YELLOW,
	## Lime color.
	LIME,
	## Lime green color.
	LIME_GREEN,
	## Linen color.
	LINEN,
	## Magenta color.
	MAGENTA,
	## Maroon color.
	MAROON,
	## Medium aquamarine color.
	MEDIUM_AQUAMARINE,
	## Medium blue color.
	MEDIUM_BLUE,
	## Medium orchid color.
	MEDIUM_ORCHID,
	## Medium purple color.
	MEDIUM_PURPLE,
	## Medium sea green color.
	MEDIUM_SEA_GREEN,
	## Medium slate blue color.
	MEDIUM_SLATE_BLUE,
	## Medium spring green color.
	MEDIUM_SPRING_GREEN,
	## Medium turquoise color.
	MEDIUM_TURQUOISE,
	## Medium violet red color.
	MEDIUM_VIOLET_RED,
	## Midnight blue color.
	MIDNIGHT_BLUE,
	## Mint cream color.
	MINT_CREAM,
	## Misty rose color.
	MISTY_ROSE,
	## Moccasin color.
	MOCCASIN,
	## Navajo white color.
	NAVAJO_WHITE,
	## Navy blue color.
	NAVY_BLUE,
	## Old lace color.
	OLD_LACE,
	## Olive color.
	OLIVE,
	## Olive drab color.
	OLIVE_DRAB,
	## Orange color.
	ORANGE,
	## Orange red color.
	ORANGE_RED,
	## Orchid color.
	ORCHID,
	## Pale goldenrod color.
	PALE_GOLDENROD,
	## Pale green color.
	PALE_GREEN,
	## Pale turquoise color.
	PALE_TURQUOISE,
	## Pale violet red color.
	PALE_VIOLET_RED,
	## Papaya whip color.
	PAPAYA_WHIP,
	## Peach puff color.
	PEACH_PUFF,
	## Peru color.
	PERU,
	## Pink color.
	PINK,
	## Plum color.
	PLUM,
	## Powder blue color.
	POWDER_BLUE,
	## Purple color.
	PURPLE,
	## Rebecca purple color.
	REBECCA_PURPLE,
	## Red color.
	RED,
	## Rosy brown color.
	ROSY_BROWN,
	## Royal blue color.
	ROYAL_BLUE,
	## Saddle brown color.
	SADDLE_BROWN,
	## Salmon color.
	SALMON,
	## Sandy brown color.
	SANDY_BROWN,
	## Sea green color.
	SEA_GREEN,
	## Seashell color.
	SEASHELL,
	## Sienna color.
	SIENNA,
	## Silver color.
	SILVER,
	## Sky blue color.
	SKY_BLUE,
	## Slate blue color.
	SLATE_BLUE,
	## Slate gray color.
	SLATE_GRAY,
	## Snow color.
	SNOW,
	## Spring green color.
	SPRING_GREEN,
	## Steel blue color.
	STEEL_BLUE,
	## Tan color.
	TAN,
	## Teal color.
	TEAL,
	## Thistle color.
	THISTLE,
	## Tomato color.
	TOMATO,
	## Transparent color (white with zero alpha).
	TRANSPARENT,
	## Turquoise color.
	TURQUOISE,
	## Violet color.
	VIOLET,
	## Web gray color.
	WEB_GRAY,
	## Web green color.
	WEB_GREEN,
	## Web maroon color.
	WEB_MAROON,
	## Web purple color.
	WEB_PURPLE,
	## Wheat color.
	WHEAT,
	## White color.
	WHITE,
	## White smoke color.
	WHITE_SMOKE,
	## Yellow color.
	YELLOW,
	## Yellow green color.
	YELLOW_GREEN,
}

## The color to fill into the box.
@export
var value := Color.WHITE

@export_group("Operations")

@export_subgroup("Named Colors")

## The named color from the [Color] class to use when setting the [member value].
@export
var named_color := NamedColors.WHITE

## Sets the [member value] to the selected [member named_color].
@export_tool_button("Set from Named Colors", "ColorRect")
var set_from_named_colors := func() -> void: value = NAMED_COLORS_LIST[named_color]

@export_subgroup("Adjustment")

## Ratio for lightening or darkening the [member value].
@export_custom(PROPERTY_HINT_RANGE, "0.0,1.0,0.01", PROPERTY_USAGE_EDITOR)
var brightness_adjustment_ratio := 0.0

## Lightens the [member value] by [member brightness_adjustment_ratio] (from 0% - 100%).
@export_tool_button("Lighten", "ArrowUp")
var lighten := func() -> void: value = value.lightened(brightness_adjustment_ratio)

## Darkens the [member value] by [member brightness_adjustment_ratio] (from 0% - 100%).
@export_tool_button("Darken", "ArrowDown")
var darken := func() -> void: value = value.darkened(brightness_adjustment_ratio)

@export_subgroup("Inversion")

## Inverts the [member value]. Does not affect transparency.
@export_tool_button("Invert (Color Only)", "Loop")
var invert_rgb := func() -> void: value = value.inverted()

## Inverts the [member value]. Affects transparency.
@export_tool_button("Invert (Color and Alpha)", "Loop")
var invert_rgba := func() -> void: value = -value

@export_subgroup("Color Spaces")

## Converts the [member value] from linear to sRGB color space.
## Assumes the color is in linear color space.
@export_tool_button("Linear to sRGB", "Color")
var linear_to_srgb := func() -> void: value = value.linear_to_srgb()

## Converts the [member value] from sRGB to linear color space.
## Assumes the color is in sRGB color space.
@export_tool_button("sRGB to Linear", "Color")
var srgb_to_linear := func() -> void: value = value.srgb_to_linear()

@export_subgroup("Blending")

## The color to blend with or towards the [member target_color].
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EDITOR)
var source_color := Color.WHITE

## Copies the [member value] to the [member source_color].
@export_tool_button("Copy Value to Source", "ActionCopy")
var copy_value_to_source := func() -> void: source_color = value

## The color for the [member source_color] to blend with or towards.
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EDITOR)
var target_color := Color.WHITE

## Overlays the [member target_color] on top of the [member value].
@export_tool_button("Blend", "Gradient")
var blend := func() -> void: value = source_color.blend(target_color)

## The weight to use when interpolating the [member source_color] to the [member target_color].
@export_custom(PROPERTY_HINT_RANGE, "0.0,1.0,0.01", PROPERTY_USAGE_EDITOR)
var interpolation_weight := 0.0

## Overlays the [member value] towards the [member target_color].
@export_tool_button("Lerp", "Curve")
var lerp := func() -> void: value = source_color.lerp(target_color, interpolation_weight)

func setup() -> void:
	data = value
