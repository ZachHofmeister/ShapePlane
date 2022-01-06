//IMPORT
import processing.pdf.*;

import controlP5.*;

import java.io.*;
import java.util.*;
import java.awt.Toolkit;
import java.awt.datatransfer.*;
import java.awt.Desktop;

//DECLARE
ArrayList<Integer> colors = new ArrayList<Integer>();
float size, colorCount, lpColorCount, hueSpacing, lpHueSpacing, satSpacing, lpSatSpacing, briSpacing, lpBriSpacing, s3, strokeWidth, perlinScale, shadowIntensity;
int xCount, yCount, currentBoxNum, mode, lpMode, startHue, startSat, startBri, startAlp, lpHue, lpSat, lpBri, shape, lpShape, preset, undoAmount, subCount, subDepth, strokeHue, strokeSat, strokeBri, rotateMin, rotateMax, noiseMode, shadowAngle;
String seed, perlinSeed, docsPath;
boolean guiState, previewGUIReset, sub, prevSub, ranPerlin, modPressed, cPressed, vPressed, trial; //horizontal
String[] prefs, defaultPrefs, imageSaveCount;
PImage raster;
public enum ShapeType {
	HEX, TRI, SQUARE, QUAD
}

ArrayList<String> prevSeeds = new ArrayList<String>();
ArrayList<Shape> shapes = new ArrayList<Shape>();
ArrayList<Shape> shapesToSub = new ArrayList<Shape>();
ArrayList<Integer> shapesToSubIndi = new ArrayList<Integer>();
ArrayList<Textfield> boxes = new ArrayList<Textfield>();
ArrayList<Textfield> boxesVis = new ArrayList<Textfield>();
ArrayList<Button> colorPreviews = new ArrayList<Button>();

ControlP5 cp5;
ControlFont f;
Slider sizeSlider, colorCountSlider, hueSpacingSlider, satSpacingSlider, briSpacingSlider, startHueSlider, startSatSlider, startBriSlider, startAlpSlider, subCountSlider, subDepthSlider,
strokeWidthSlider, strokeHueSlider, strokeSatSlider, strokeBriSlider,
rotationMinSlider, rotationMaxSlider,
perlinScaleSlider,
shadowAngleSlider, shadowIntensitySlider;
Textfield sizeBox, colorCountBox, hueSpacingBox, satSpacingBox, briSpacingBox, startHueBox, startSatBox, startBriBox, startAlpBox, presetSaveNameBox, seedBox, subCountBox, subDepthBox,
strokeWidthBox, strokeHueBox, strokeSatBox, strokeBriBox,
rotationMinBox, rotationMaxBox,
perlinSeedBox, perlinScaleBox,
shadowAngleBox, shadowIntensityBox;
ListBox modeList, shapeList, presetList, noiseList;
ScrollableList subList;
ArrayList<Boolean> subs = new ArrayList<Boolean>();
ArrayList<Boolean> subsTri = new ArrayList<Boolean>();
ArrayList<Boolean> subsSquare = new ArrayList<Boolean>();
ArrayList<Boolean> subsHex = new ArrayList<Boolean>();
Toggle subToggle, perlinRandomizeToggle;
Textlabel previewTextlabel;


void setup() {
	//INITIALIZE
	size(1000, 1000);
	frameRate(60);
	
	PImage icon = loadImage("data/icon_512x512.png");
	PGraphics iconGraphics = createGraphics(512,512,JAVA2D);
	iconGraphics.beginDraw();
	iconGraphics.image(icon,0,0);
	iconGraphics.endDraw();
	surface.setIcon(icon);
	surface.setTitle("ShapePlane v" + loadStrings("data/version.txt")[0]);
	
	noSmooth();
	defaultPrefs = loadStrings("data/defaultPrefs.txt");
	s3 = (float)Math.sqrt(3);
	lpShape = -1;
	
	docsPath = System.getProperty("user.home") + File.separator + "Documents" + File.separator;
	if (!(new File(docsPath + "ShapePlane")).exists()) {
	   (new File(docsPath + "ShapePlane")).mkdir();
	}
	if (!(new File(docsPath + "ShapePlane/presets")).exists()) {
	   (new File(docsPath + "ShapePlane/presets")).mkdir();
	}
	if (!(new File(docsPath + "ShapePlane/images")).exists()) {
	   (new File(docsPath + "ShapePlane/images")).mkdir();
	}
	if (!(new File(docsPath + "ShapePlane/imageSaveCount.txt")).exists()) {
		saveStrings(docsPath + "ShapePlane/imageSaveCount.txt", new String[] {"0"});
	}
	
	//GUI INITIALIZE
	cp5 = new ControlP5(this);
	// The below uses a non-standard (to processing) font. Otherwise a smaller but cleaner font is used.
	// f = new ControlFont(createFont("Monospaced", 17, false));
	// cp5.setFont(f);
	cp5.setColorActive(color(255));
	cp5.setColorBackground(color(150, 150, 150));
	cp5.setColorForeground(color(200, 200, 200));
	
	cp5.getTab("default").setLabel("Main").activateEvent(true).setColorLabel(0);
	cp5.addTab("Color").activateEvent(true).setColorLabel(0);
	cp5.addGroup("allTabs").setLabel("");
	
	Button generateButton = cp5.addButton("drawPlane").setPosition(20,20).setSize(120,30).setCaptionLabel("Generate").setColorLabel(color(0, 0, 0)).setGroup("allTabs");
		seedBox = cp5.addTextfield("_seed").setPosition(140,20).setSize(120,30).setCaptionLabel("").setText("").setColorValue(color(0,0,0)).setColorActive(color(255,0,0)).setGroup("allTabs");
		boxes.add(seedBox);
	Button savePrefsButton = cp5.addButton("savePrefs").setPosition(280,20).setSize(120,30).setCaptionLabel("Save Preset").setColorLabel(color(0, 0, 0)).setGroup("allTabs");
		presetSaveNameBox = cp5.addTextfield("_presetSaveName").setPosition(400,20).setSize(120,30).setCaptionLabel("").setText("newPreset").setColorValue(color(0,0,0)).setColorActive(color(255,0,0)).setGroup("allTabs");
		boxes.add(presetSaveNameBox);
	Button loadPrefsButton = cp5.addButton("loadPrefs").setPosition(540,20).setSize(120,30).setCaptionLabel("Load Preset").setColorLabel(color(0, 0, 0)).setGroup("allTabs");
	Button deletePrefsButton = cp5.addButton("delPrefs").setPosition(540,50).setSize(120,30).setCaptionLabel("DEL Preset").setColorLabel(color(0, 0, 0)).setGroup("allTabs");
		presetList = cp5.addListBox("preset").setPosition(670,20).setSize(200,60).setCaptionLabel("Presets").setValue(0).setBarHeight(30).setItemHeight(30).setType(0)
		   .addItems(new String[] {"INITIAL"}).setColorLabel(color(0, 0, 0)).setColorValue(color(0, 0, 0)).setGroup("allTabs");
	Button loadDefaultPrefsButton = cp5.addButton("loadDefault").setPosition(890,20).setSize(90,60).setCaptionLabel("Load\nDefault").setColorLabel(color(0, 0, 0)).setGroup("allTabs");
	
	sizeSlider = cp5.addSlider("size").setPosition(70,90).setSize(400,30).setCaptionLabel("Grid Height").setRange(1,150).setColorValue(color(0)).setColorLabel(color(255));
	sizeSlider.getValueLabel().setVisible(false);
	sizeBox = cp5.addTextfield("_size").setPosition(20,90).setSize(50,30).setCaptionLabel("").setColorValue(color(0,0,0)).setInputFilter(controlP5.Textfield.INTEGER).setColorActive(color(255,0,0));
	boxes.add(sizeBox);
	
	strokeWidthSlider = cp5.addSlider("strokeWidth").setPosition(70,130).setSize(400,30).setCaptionLabel("Stroke Width").setRange(0,20).setColorValue(color(0)).setColorLabel(color(255));
	strokeWidthSlider.getValueLabel().setVisible(false);
	strokeWidthBox = cp5.addTextfield("_strokeWidth").setPosition(20,130).setSize(50,30).setCaptionLabel("").setColorValue(color(0,0,0)).setColorActive(color(255,0,0));
	boxes.add(strokeWidthBox);
	
	shapeList = cp5.addListBox("shape").setPosition(650,90).setSize(300,240).setCaptionLabel("Shape").setBarHeight(30).setItemHeight(30).setType(0)
	   .addItems(new String[] {"Equilateral Triangle", "Hexagon", "Square", "Square Offset", "Right Triangle", "Right Triangle Offset"})
	   .setColorLabel(color(0, 0, 0)).setColorValue(color(0, 0, 0));
	
	subToggle = cp5.addToggle("sub").setPosition(20,170).setSize(30,30).setCaptionLabel("");
		Textlabel toggleLabel = cp5.addTextlabel("Caption").setPosition(51,172).setText("SUBDIVIDE");
	
	subCountSlider = cp5.addSlider("subCount").setPosition(70,200).setSize(400,30).setCaptionLabel("Subdivision Count").setRange(1,10000).setColorValue(color(0)).setColorLabel(color(255));
	subCountSlider.getValueLabel().setVisible(false);
	subCountBox = cp5.addTextfield("_subCount").setPosition(20,200).setSize(50,30).setCaptionLabel("").setColorValue(color(0,0,0)).setColorActive(color(255,0,0));
	boxes.add(subCountBox);
	
	subDepthSlider = cp5.addSlider("subDepth").setPosition(70,230).setSize(400,30).setCaptionLabel("Subdivision Depth").setRange(1,20).setColorValue(color(0)).setColorLabel(color(255));
	subDepthSlider.getValueLabel().setVisible(false);
	subDepthBox = cp5.addTextfield("_subDepth").setPosition(20,230).setSize(50,30).setCaptionLabel("").setColorValue(color(0,0,0)).setColorActive(color(255,0,0));
	boxes.add(subDepthBox);
	
	noiseList = cp5.addListBox("noiseMode").setPosition(20,270).setSize(300,150).setCaptionLabel("Noise Mode").setBarHeight(30).setItemHeight(30).setType(0)
	   .addItems(new String[] {"Off", "Color", "Brightness Tint", "Saturation Tint"}).setColorLabel(color(0, 0, 0)).setColorValue(color(0, 0, 0));
	
	Button randomPerlinSeed = cp5.addButton("randomizePerlinSeed").setPosition(20,420).setSize(150,30).setCaptionLabel("Perlin Seed").setColorLabel(color(0, 0, 0));
		perlinSeedBox = cp5.addTextfield("perlinSeed").setPosition(170,420).setSize(150,30).setCaptionLabel("").setText(defaultPrefs[16]).setColorValue(color(0,0,0)).setColorActive(color(255,0,0));
		boxes.add(perlinSeedBox);
		perlinRandomizeToggle = cp5.addToggle("ranPerlin").setPosition(330,420).setSize(30,30).setCaptionLabel("");
			Textlabel toggleLabel2 = cp5.addTextlabel("Caption2").setPosition(361,422).setText("RANDOM ON GENERATE");
	
	perlinScaleSlider = cp5.addSlider("pperlinScale").setPosition(90,450).setSize(230,30).setCaptionLabel("Perlin Scale").setRange( - 0.001,.2).setColorValue(color(0)).setColorLabel(color(255));
	perlinScaleSlider.getValueLabel().setVisible(false);
	perlinScaleBox = cp5.addTextfield("_perlinScale").setPosition(20,450).setSize(70,30).setCaptionLabel("").setColorValue(color(0,0,0)).setColorActive(color(255,0,0));
	boxes.add(perlinScaleBox);
	
	subList = cp5.addScrollableList("subList").setPosition(650,400).setSize(300,300).setCaptionLabel("Subdivision Types").setBarHeight(30).setItemHeight(30).setType(2)
	   .addItems(new String[] {})
	   .setColorLabel(color(0, 0, 0)).setColorValue(color(0, 0, 0));
	
	// rotationMinSlider = cp5.addSlider("rotateMin").setPosition(70,440).setSize(300,30).setCaptionLabel("Min Rotation").setRange(-180,180).setColorValue(color(0, 0, 0));
	// rotationMinSlider.getValueLabel().setVisible(false);
	// rotationMinBox = cp5.addTextfield("_rotateMin").setPosition(20,440).setSize(50,30).setCaptionLabel("").setColorValue(color(0,0,0)).setColorActive(color(255,0,0));
	// boxes.add(rotationMinBox);
	// rotationMaxSlider = cp5.addSlider("rotateMax").setPosition(70,470).setSize(300,30).setCaptionLabel("Max Rotation").setRange(-180,180).setColorValue(color(0, 0, 0));
	// rotationMaxSlider.getValueLabel().setVisible(false);
	// rotationMaxBox = cp5.addTextfield("_rotateMax").setPosition(20,470).setSize(50,30).setCaptionLabel("").setColorValue(color(0,0,0)).setColorActive(color(255,0,0));
	// boxes.add(rotationMaxBox);
	
	
	
	colorCountSlider = cp5.addSlider("colorCount").setPosition(70,90).setSize(400,30).setCaptionLabel("Color Count").setRange(1,100).setColorValue(color(0)).setColorLabel(color(255)).setTab("Color");
	colorCountSlider.getValueLabel().setVisible(false);
	colorCountBox = cp5.addTextfield("_colorCount").setPosition(20,90).setSize(50,30).setCaptionLabel("").setColorValue(color(0,0,0)).setInputFilter(controlP5.Textfield.INTEGER).setColorActive(color(255,0,0)).setTab("Color");
	boxes.add(colorCountBox);
	
	startHueSlider = cp5.addSlider("startHue").setPosition(70,130).setSize(400,30).setCaptionLabel("Base Hue").setRange( - 1,360).setColorValue(color(0)).setColorLabel(color(255)).setTab("Color");
	startHueSlider.getValueLabel().setVisible(false);
	startHueBox = cp5.addTextfield("_startHue").setPosition(20,130).setSize(50,30).setCaptionLabel("").setColorValue(color(0,0,0)).setColorActive(color(255,0,0)).setTab("Color");
	boxes.add(startHueBox);
	startSatSlider = cp5.addSlider("startSat").setPosition(70,160).setSize(400,30).setCaptionLabel("Base Saturation").setRange( - 1,100).setColorValue(color(0)).setColorLabel(color(255)).setTab("Color");
	startSatSlider.getValueLabel().setVisible(false);
	startSatBox = cp5.addTextfield("_startSat").setPosition(20,160).setSize(50,30).setCaptionLabel("").setColorValue(color(0,0,0)).setColorActive(color(255,0,0)).setTab("Color");
	boxes.add(startSatBox);
	startBriSlider = cp5.addSlider("startBri").setPosition(70,190).setSize(400,30).setCaptionLabel("Base Brightness").setRange( - 1,100).setColorValue(color(0)).setColorLabel(color(255)).setTab("Color");
	startBriSlider.getValueLabel().setVisible(false);
	startBriBox = cp5.addTextfield("_startBri").setPosition(20,190).setSize(50,30).setCaptionLabel("").setColorValue(color(0,0,0)).setColorActive(color(255,0,0)).setTab("Color");
	boxes.add(startBriBox);
	
	hueSpacingSlider = cp5.addSlider("hueSpacing").setPosition(70,230).setSize(400,30).setCaptionLabel("Hue Spacing").setRange(0,360).setColorValue(color(0)).setColorLabel(color(255)).setTab("Color");
	hueSpacingSlider.getValueLabel().setVisible(false);
	hueSpacingBox = cp5.addTextfield("_hueSpacing").setPosition(20,230).setSize(50,30).setCaptionLabel("").setColorValue(color(0,0,0)).setInputFilter(controlP5.Textfield.INTEGER).setColorActive(color(255,0,0)).setTab("Color");
	boxes.add(hueSpacingBox);
	satSpacingSlider = cp5.addSlider("satSpacing").setPosition(70,260).setSize(400,30).setCaptionLabel("Sat Spacing").setRange(0,100).setColorValue(color(0)).setColorLabel(color(255)).setTab("Color");
	satSpacingSlider.getValueLabel().setVisible(false);
	satSpacingBox = cp5.addTextfield("_satSpacing").setPosition(20,260).setSize(50,30).setCaptionLabel("").setColorValue(color(0,0,0)).setInputFilter(controlP5.Textfield.INTEGER).setColorActive(color(255,0,0)).setTab("Color");
	boxes.add(satSpacingBox);
	briSpacingSlider = cp5.addSlider("briSpacing").setPosition(70,290).setSize(400,30).setCaptionLabel("Bri Spacing").setRange(0,100).setColorValue(color(0)).setColorLabel(color(255)).setTab("Color");
	briSpacingSlider.getValueLabel().setVisible(false);
	briSpacingBox = cp5.addTextfield("_briSpacing").setPosition(20,290).setSize(50,30).setCaptionLabel("").setColorValue(color(0,0,0)).setInputFilter(controlP5.Textfield.INTEGER).setColorActive(color(255,0,0)).setTab("Color");
	boxes.add(briSpacingBox);
	
	strokeHueSlider = cp5.addSlider("strokeHue").setPosition(70,330).setSize(400,30).setCaptionLabel("Stroke Hue").setRange(0,360).setColorValue(color(0)).setColorLabel(color(255)).setTab("Color");
	strokeHueSlider.getValueLabel().setVisible(false);
	strokeHueBox = cp5.addTextfield("_strokeHue").setPosition(20,330).setSize(50,30).setCaptionLabel("").setColorValue(color(0,0,0)).setColorActive(color(255,0,0)).setTab("Color");
	boxes.add(strokeHueBox);
	strokeSatSlider = cp5.addSlider("strokeSat").setPosition(70,360).setSize(400,30).setCaptionLabel("Stroke Saturation").setRange(0,100).setColorValue(color(0)).setColorLabel(color(255)).setTab("Color");
	strokeSatSlider.getValueLabel().setVisible(false);
	strokeSatBox = cp5.addTextfield("_strokeSat").setPosition(20,360).setSize(50,30).setCaptionLabel("").setColorValue(color(0,0,0)).setColorActive(color(255,0,0)).setTab("Color");
	boxes.add(strokeSatBox);
	strokeBriSlider = cp5.addSlider("strokeBri").setPosition(70,390).setSize(400,30).setCaptionLabel("Stroke Brightness").setRange(0,100).setColorValue(color(0)).setColorLabel(color(255)).setTab("Color");
	strokeBriSlider.getValueLabel().setVisible(false);
	strokeBriBox = cp5.addTextfield("_strokeBri").setPosition(20,390).setSize(50,30).setCaptionLabel("").setColorValue(color(0,0,0)).setColorActive(color(255,0,0)).setTab("Color");
	boxes.add(strokeBriBox);
	
	shadowAngleSlider = cp5.addSlider("shadowAngle").setPosition(70,430).setSize(400,30).setCaptionLabel("Shadow Angle").setRange(0,360).setColorValue(color(0)).setColorLabel(color(255)).hide().setTab("Color");
	shadowAngleSlider.getValueLabel().setVisible(false);
	shadowAngleBox = cp5.addTextfield("_shadowAngle").setPosition(20,430).setSize(50,30).setCaptionLabel("").setColorValue(color(0,0,0)).setColorActive(color(255,0,0)).hide().setTab("Color");
	boxes.add(shadowAngleBox);
	
	shadowIntensitySlider = cp5.addSlider("shadowIntensity").setPosition(70,460).setSize(400,30).setCaptionLabel("Shadow Intensity").setRange(0,50).setColorValue(color(0)).setColorLabel(color(255)).hide().setTab("Color");
	shadowIntensitySlider.getValueLabel().setVisible(false);
	shadowIntensityBox = cp5.addTextfield("_shadowIntensity").setPosition(20,460).setSize(50,30).setCaptionLabel("").setColorValue(color(0,0,0)).setColorActive(color(255,0,0)).hide().setTab("Color");
	boxes.add(shadowIntensityBox);
	
	modeList = cp5.addListBox("mode").setPosition(650,90).setSize(300,450).setCaptionLabel("Color Harmony").setBarHeight(30).setItemHeight(30).setType(0)
	   .addItems(new String[] {"Intermediate", "Analogous", "Shades", "Monochromatic", "Complimentary", "Left Complimentary", "Right Complimentary", "Split Complimentary", "Triad", "Tetrad", "Pentagram", "Compound Left", "Compound Right"})
	   .setColorLabel(color(0, 0, 0)).setColorValue(color(0, 0, 0)).setTab("Color");
	
	if (!sub) {
		subCountSlider.hide();
		subCountBox.hide();
		subDepthSlider.hide();
		subDepthBox.hide();
	}
	
	previewTextlabel = cp5.addTextlabel("_text").setPosition(20, height - 120).setSize(200,30).setText("Color Palette Preview").setTab("Color");
	
	cp5.hide();
	//CONTINUE INITIALIZE
	loadDefault();
	updatePresetList();
	randomizePerlinSeed();
	drawPlane();
}

void draw() {
	if (guiState) {
		boxesVis.clear();
		for (Textfield t : boxes) {
			if (t.isVisible() && t.getTab().isActive()) {
				boxesVis.add(t);
			}
		}
		
		updateColorPickers();
		
		subList.setSize(300, 30 + 30 * subList.getItems().size());
		if (shape != lpShape) {
			refreshSubs();
			image(raster, 0, 0);
			toggleGUI(true);
		}
		subs.clear();
		for (int i = 0; i < subList.getItems().size(); i++) {
			subs.add((boolean)subList.getItem(i).get("state"));
		}
		
		loneBoxManage(seedBox);
		loneBoxManage(presetSaveNameBox);
		size = (int)boxSliderBalance(size, sizeBox, sizeSlider, 0);
		colorCount = (int)boxSliderBalance(colorCount, colorCountBox, colorCountSlider, 0);
		startHue = (int)boxSliderBalance(startHue, startHueBox, startHueSlider, 0);
		startSat = (int)boxSliderBalance(startSat, startSatBox, startSatSlider, 0);
		startBri = (int)boxSliderBalance(startBri, startBriBox, startBriSlider, 0);
		hueSpacing = (int)boxSliderBalance(hueSpacing, hueSpacingBox, hueSpacingSlider, 0);
		satSpacing = (int)boxSliderBalance(satSpacing, satSpacingBox, satSpacingSlider, 0);
		briSpacing = (int)boxSliderBalance(briSpacing, briSpacingBox, briSpacingSlider, 0);
		strokeWidth = boxSliderBalance(strokeWidth, strokeWidthBox, strokeWidthSlider, 2);
		strokeHue = (int)boxSliderBalance(strokeHue, strokeHueBox, strokeHueSlider, 0);
		strokeSat = (int)boxSliderBalance(strokeSat, strokeSatBox, strokeSatSlider, 0);
		strokeBri = (int)boxSliderBalance(strokeBri, strokeBriBox, strokeBriSlider, 0);
		subCount = (int)boxSliderBalance(subCount, subCountBox, subCountSlider, 0);
		subDepth = (int)boxSliderBalance(subDepth, subDepthBox, subDepthSlider, 0);
		shadowAngle = (int)boxSliderBalance(shadowAngle, shadowAngleBox, shadowAngleSlider, 0);
		shadowIntensity = boxSliderBalance(shadowIntensity, shadowIntensityBox, shadowIntensitySlider, 1);
		loneBoxManage(perlinSeedBox);
		perlinScale = boxSliderBalance(perlinScale, perlinScaleBox, perlinScaleSlider, 3);
		
		// size = round(size);
		// colorCount = round(colorCount);
		
		if (lpColorCount != colorCount || lpHue != startHue || lpSat != startSat || lpBri != startBri || lpHueSpacing != hueSpacing || lpSatSpacing != satSpacing || lpBriSpacing != briSpacing || lpMode != mode || !previewGUIReset) {
			updateColorPreview();
			lpColorCount = colorCount;
			lpHue = startHue;
			lpSat = startSat;
			lpBri = startBri;
			lpHueSpacing = hueSpacing;
			lpSatSpacing = satSpacing;
			lpBriSpacing = briSpacing;
			lpMode = mode;
			previewGUIReset = true;
		}
		
		if (sub && !prevSub) {
			subCountSlider.show();
			subCountBox.show();
			subDepthSlider.show();
			subDepthBox.show();
			prevSub = true;
		} else if (!sub && prevSub) {
			subCountSlider.hide();
			subCountBox.hide();
			subDepthSlider.hide();
			subDepthBox.hide();
			image(raster, 0, 0);
			toggleGUI(true);
			prevSub = false;
		}
		
		if (shape == 8 && !shadowAngleSlider.isVisible()) {
			shadowAngleSlider.show();
			shadowAngleBox.show();
			shadowIntensitySlider.show();
			shadowIntensityBox.show();
		} else if (shape != 8 && shadowAngleSlider.isVisible()) {
			shadowAngleSlider.hide();
			shadowAngleBox.hide();
			shadowIntensitySlider.hide();
			shadowIntensityBox.hide();
			image(raster, 0, 0);
			toggleGUI(true);
		}
		
		for (int i = 0; i < colorPreviews.size(); i++) {
			if (colorPreviews.get(i).isPressed()) {
				copyString((String)hex(colors.get(i), 6));
			}
		}
	}
}

void refreshSubs() {
	if (lpShape == 0 || lpShape == 4 || lpShape == 5) { //Triangle
		subsTri.clear();
		for (int i = 0; i < subs.size(); i++) {
			subsTri.add(subs.get(i));
		}
	} else if (lpShape == 1) { //Hexagon
		subsHex.clear();
		for (int i = 0; i < subs.size(); i++) {
			subsHex.add(subs.get(i));
		}
	} else if (lpShape == 2 || lpShape == 3) { //Square
		subsSquare.clear();
		for (int i = 0; i < subs.size(); i++) {
			subsSquare.add(subs.get(i));
		}
	}
	subList.clear();
	if (shape == 0 || shape == 4 || shape == 5) { //Triangle
		subList.addItems(new String[] {"4 Triangles", "Vertex to Midpoint", "Center Split"});
		for (int i = 0; i < subList.getItems().size(); i++) {
			subList.getItem(i).put("state", subsTri.get(i));
		}
	} else if (shape == 1) { //Hexagon
		subList.addItems(new String[] {"Inscribe Triangle", "3-Way Split", "4-Way Split", "6-Way Split", "Half"});
		for (int i = 0; i < subList.getItems().size(); i++) {
			subList.getItem(i).put("state", subsHex.get(i));
		}
	} else if (shape == 2 || shape == 3) { //Square
		subList.addItems(new String[] {"Quarters", "Diagonal", "Half", "Inscribe Diamond"});
		for (int i = 0; i < subList.getItems().size(); i++) {
			subList.getItem(i).put("state", subsSquare.get(i));
		}
	}
	lpShape = shape;
}

void drawPlane() {
	shapes.clear();
	imageSaveCount = loadStrings(docsPath + "ShapePlane/imageSaveCount.txt");
	if (seedBox.getText().compareTo("") == 0) {
		seed = "" + int(unaffectedRandomRange(0, 999999999));
		while(seed.length() < 10) {
			seed = "0" + seed;
		}
		seedBox.setText(seed);
	} else {
		seed = seedBox.getText();
	}
	if (!prevSeeds.contains(seed)) {
		undoAmount = 1;
		prevSeeds.add(seed);
	}
	if (prevSeeds.size() > 99) {
		prevSeeds.remove(0);
	}
	randomSeed(seed.hashCode());
	clearEmptyFiles();
	if (!trial) {
		beginRecord(PDF, docsPath + "ShapePlane/images/ShapePlane-" + int(imageSaveCount[0]) + ".pdf");
	}
	colorMode(HSB, 360, 100, 100, 100);
	rectMode(CORNERS);
	background(360);
	
	if (perlinScaleSlider.getValue() < 0) {
		perlinScale = random(0,.2);
	} else {
		perlinScale = perlinScaleSlider.getValue();
	}
	
	if (strokeWidth > 0) {
		strokeWeight(strokeWidth);
		stroke(color(strokeHue, strokeSat, strokeBri));
		strokeCap(PROJECT);
	} else {
		noStroke();
	}
	
	toggleGUI(false);
	
	if (shape == 0 || shape == 1 || shape == 8) {
		xCount = int(size * s3);
		yCount = int(size * 4 / 3);
	} else if (shape == 3 || shape == 5 || shape == 7) {
		xCount = int(size);
		yCount = int(size) - 1;
	} else {
		xCount = int(size) - 1;
		yCount = int(size) - 1;
	}
	genColors(round(colorCount));
	
	for (int y = 0; y <= yCount; y++) {
		for (int x = 0; x <= xCount; x++) {
			pointData leftTop = new pointData(x * height / size / 2 * s3 - (y % 2 ==  0 ? 0 : height / size / 4 * s3), y * height / size - height / size / 4 * y);
			pointData top = new pointData((x * height / size / 2 * s3 - (y % 2 ==  0 ? 0 : height / size / 4 * s3)) + height / size / 4 * s3, y * height / size - height / size / 4 - height / size / 4 * y);
			pointData rightTop = new pointData((x * height / size / 2 * s3 - (y % 2 ==  0 ? 0 : height / size / 4 * s3)) + height / size / 2 * s3, y * height / size - height / size / 4 * y);
			pointData rightBottom = new pointData((x * height / size / 2 * s3 - (y % 2 ==  0 ? 0 : height / size / 4 * s3)) + height / size / 2 * s3, y * height / size + height / size / 2 - height / size / 4 * y);
			pointData bottom = new pointData((x * height / size / 2 * s3 - (y % 2 ==  0 ? 0 : height / size / 4 * s3)) + height / size / 4 * s3, y * height / size + height / size * 3 / 4 - height / size / 4 * y);
			pointData leftBottom = new pointData(x * height / size / 2 * s3 - (y % 2 ==  0 ? 0 : height / size / 4 * s3), y * height / size + height / size / 2 - height / size / 4 * y);
			pointData center = new pointData((x * height / size / 2 * s3 - (y % 2 ==  0 ? 0 : height / size / 4 * s3)) + height / size / 4 * s3, y * height / size + height / size / 4 - height / size / 4 * y);
			pointData squareTL = new pointData(x * height / size,y * height / size);
			pointData squareTR = new pointData((x + 1) * height / size,y * height / size);
			pointData squareBL = new pointData(x * height / size,(y + 1) * height / size);
			pointData squareBR = new pointData((x + 1) * height / size,(y + 1) * height / size);
			pointData squareOTL = new pointData(x * height / size - (y % 2 ==  0 ? 0 : height / size / 2),y * height / size);
			pointData squareOTR = new pointData((x + 1) * height / size - (y % 2 ==  0 ? 0 : height / size / 2),y * height / size);
			pointData squareOBL = new pointData(x * height / size - (y % 2 ==  0 ? 0 : height / size / 2),(y + 1) * height / size);
			pointData squareOBR = new pointData((x + 1) * height / size - (y % 2 ==  0 ? 0 : height / size / 2),(y + 1) * height / size);
			
			switch(shape) {
				case 0 : //Equilateral Triangle
					   shapes.add(new Shape(ShapeType.TRI, leftTop, top, center));
					   shapes.add(new Shape(ShapeType.TRI, top, rightTop, center));
					   shapes.add(new Shape(ShapeType.TRI, rightTop, rightBottom, center));
					   shapes.add(new Shape(ShapeType.TRI, rightBottom, bottom, center));
					   shapes.add(new Shape(ShapeType.TRI, bottom, leftBottom, center));
					   shapes.add(new Shape(ShapeType.TRI, leftBottom, leftTop, center));
					   break;
				case 1 : //Hexagon
					   shapes.add(new Shape(ShapeType.HEX, leftTop, top, rightTop, rightBottom, bottom, leftBottom));
					   break;
				case 2 : //Square
					   shapes.add(new Shape(ShapeType.SQUARE, squareTL, squareBR));
					   break;
				case 3 : //Square Offset
					   shapes.add(new Shape(ShapeType.SQUARE, squareOTL, squareOBR));
					   break;
				case 4 : //Right Triangle
					   if (getRandomBoolean()) {
						   shapes.add(new Shape(ShapeType.TRI, squareTL, squareTR, squareBR));
						   shapes.add(new Shape(ShapeType.TRI, squareTL, squareBL, squareBR));
					   } else {
						   shapes.add(new Shape(ShapeType.TRI, squareTR, squareBR, squareBL));
						   shapes.add(new Shape(ShapeType.TRI, squareTL, squareTR, squareBL));
					   }
					   break;
				case 5 : //Right Triangle Offset
					   if (getRandomBoolean()) {
						   shapes.add(new Shape(ShapeType.TRI, squareOTR, squareOTL, squareOBR));
						   shapes.add(new Shape(ShapeType.TRI, squareOBL, squareOTL, squareOBR));
					   } else {
						   shapes.add(new Shape(ShapeType.TRI, squareOBR, squareOTR, squareOBL));
						   shapes.add(new Shape(ShapeType.TRI, squareOTL, squareOTR, squareOBL));
					   }
					   break;
				// case 6: //Cube
				// 	color base = rColor(center);
				//     // fill(color(hue(base), saturation(base), brightness(base) - hueSpacing * 2));
				//     fill(color(hue(base), saturation(base), brightness(base) - (shadowIntensity * withinLoopBounds(shadowAngle + 120, 360f)/180f)));
				//     quadra(leftBottom, leftTop, center, bottom);
				//     shapes.add(new Shape(ShapeType.QUAD, leftBottom, leftTop, center, bottom));
				//     // fill(base);
				//     fill(color(hue(base), saturation(base), brightness(base) - (shadowIntensity * withinLoopBounds(shadowAngle, 360f)/180f)));
				//     quadra(top, rightTop, center, leftTop);
				//     shapes.add(new Shape(ShapeType.QUAD, top, rightTop, center, leftTop));
				//     // fill(color(hue(base), saturation(base), brightness(base) - hueSpacing));
				//     fill(color(hue(base), saturation(base), brightness(base) - (shadowIntensity * withinLoopBounds(shadowAngle + 240, 360f)/180f)));
				//     quadra(rightBottom, rightTop, center, bottom);
				//     shapes.add(new Shape(ShapeType.QUAD, rightBottom, rightTop, center, bottom));
				//     break;
			}
		}
	}
	
	if (shapes.size() > 0 && sub) {
		subDivide();
	}
	
	for (Shape s : shapes) {
		fill(rColor(s));
		drawPoly(s);
	}
}

void subDivide() {
	shapesToSub.clear();
	refreshSubs();
	boolean triS, hexS, squS;
	triS = hexS = squS = false;
	for (boolean b : subsTri) {
		if (b) {
			triS = true;
		}
	}
	for (boolean b : subsHex) {
		if (b) {
			hexS = true;
		}
	}
	for (boolean b : subsSquare) {
		if (b) {
			squS = true;
		}
	}
	
	for (int i = 0; i < shapes.size(); i++) {
		if (shapes.get(i).depth < Integer.parseInt(subDepthBox.getText()) && ((shapes.get(i).type == ShapeType.TRI && triS) || (shapes.get(i).type == ShapeType.HEX && hexS) || (shapes.get(i).type == ShapeType.SQUARE && squS))) {
			shapesToSub.add(new Shape(shapes.get(i)));
		}
	}
	for (int i = 0; i < subCount; i++) {
		if (shapesToSub.size() <= 0) {
			break;
		}
		int index = int(random(0, shapesToSub.size()));
		Shape s = shapesToSub.get(index);
		
		refreshSubs();
		if (s.type == ShapeType.TRI) {
			ArrayList<Integer> subOptions = new ArrayList<Integer>();
			for (int j = 0; j < subsTri.size(); j++) {
				if (subsTri.get(j)) {
					   subOptions.add(j);
				   }
			}
			if (subOptions.size() <= 0) {
				continue;
			} else {
				shapesToSub.remove(index);
			}
			int subIndex = getRandomCase(subOptions.size());
			switch(subOptions.get(subIndex)) {
				case 0 : {//4 Triangles
					pointData oneTwo = midPoint(s.points.get(0), s.points.get(1));
					pointData twoThree = midPoint(s.points.get(1), s.points.get(2));
					pointData threeOne = midPoint(s.points.get(2), s.points.get(0));
					shapes.add(new Shape(ShapeType.TRI, s.depth + 1, oneTwo, twoThree, threeOne));
					shapes.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(0), oneTwo, threeOne));
					shapes.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(1), oneTwo, twoThree));
					shapes.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(2), threeOne, twoThree));
					if (s.depth + 1 < Integer.parseInt(subDepthBox.getText()) && triS) {
						shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1, oneTwo, twoThree, threeOne));
						shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(0), oneTwo, threeOne));
						shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(1), oneTwo, twoThree));
						shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(2), threeOne, twoThree));
					}
					break;}
				case 1 : {//Vertex-Midpoint
					pointData oneTwo = midPoint(s.points.get(0), s.points.get(1));
					pointData twoThree = midPoint(s.points.get(1), s.points.get(2));
					pointData threeOne = midPoint(s.points.get(2), s.points.get(0));
					switch(getRandomCase(3)) {
						case 0:
							shapes.add(new Shape(ShapeType.TRI, s.depth + 1,  s.points.get(0), s.points.get(1), threeOne));
							shapes.add(new Shape(ShapeType.TRI, s.depth + 1,  s.points.get(2), s.points.get(1), threeOne));
							if (s.depth + 1 < Integer.parseInt(subDepthBox.getText()) && triS) {
								shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1,  s.points.get(0), s.points.get(1), threeOne));
								shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1,  s.points.get(2), s.points.get(1), threeOne));
							}
							break;
						case 1:
							shapes.add(new Shape(ShapeType.TRI, s.depth + 1,  s.points.get(1), s.points.get(2), oneTwo));
							shapes.add(new Shape(ShapeType.TRI, s.depth + 1,  s.points.get(0), s.points.get(2), oneTwo));
							if (s.depth + 1 < Integer.parseInt(subDepthBox.getText()) && triS) {
								shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1,  s.points.get(1), s.points.get(2), oneTwo));
								shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1,  s.points.get(0), s.points.get(2), oneTwo));
							}
							break;
						case 2:
							shapes.add(new Shape(ShapeType.TRI, s.depth + 1,  s.points.get(2), s.points.get(0), twoThree));
							shapes.add(new Shape(ShapeType.TRI, s.depth + 1,  s.points.get(1), s.points.get(0), twoThree));
							if (s.depth + 1 < Integer.parseInt(subDepthBox.getText()) && triS) {
								shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1,  s.points.get(2), s.points.get(0), twoThree));
								shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1,  s.points.get(1), s.points.get(0), twoThree));
							}
							break;
					}
					break;}
				case 2 : {//Center Split
					//pointData oneTwo = midPoint(s.points.get(0), s.points.get(1));
					//pointData twoThree = midPoint(s.points.get(1), s.points.get(2));
					//pointData threeOne = midPoint(s.points.get(2), s.points.get(0));
					pointData cen = midPoint(new pointData[] {s.points.get(0), s.points.get(1), s.points.get(2)});
					shapes.add(new Shape(ShapeType.TRI, s.depth + 1,  s.points.get(0), s.points.get(1), cen));
					shapes.add(new Shape(ShapeType.TRI, s.depth + 1,  s.points.get(1), s.points.get(2), cen));
					shapes.add(new Shape(ShapeType.TRI, s.depth + 1,  s.points.get(2), s.points.get(0), cen));
					if (s.depth + 1 < Integer.parseInt(subDepthBox.getText()) && triS) {
						shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1,  s.points.get(0), s.points.get(1), cen));
						shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1,  s.points.get(1), s.points.get(2), cen));
						shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1,  s.points.get(2), s.points.get(0), cen));
					}
					break;}
			   }
		} else if (s.type == ShapeType.HEX) {
			ArrayList<Integer> subOptions = new ArrayList<Integer>();
			for (int j = 0; j < subsHex.size(); j++) {
				if (subsHex.get(j)) {
					subOptions.add(j);
				}
			}
			if (subOptions.size() <= 0) {
				continue;
			} else {
				shapesToSub.remove(index);
			}
			int subIndex = getRandomCase(subOptions.size());
			switch(subOptions.get(subIndex)) {
				case 0 : {//Inscribe triangle
					   // pointData oneTwo = midPoint(s.points.get(0),s.points.get(1));
					   // pointData twoThree = midPoint(s.points.get(1),s.points.get(2));
					   // pointData threeFour = midPoint(s.points.get(2),s.points.get(3));
					   // pointData fourFive = midPoint(s.points.get(3),s.points.get(4));
					   // pointData fiveSix = midPoint(s.points.get(4),s.points.get(5));
					   // pointData sixOne = midPoint(s.points.get(5),s.points.get(0));
					   switch(getRandomCase(2)) {
						   case 0:
							   shapes.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(0), s.points.get(2), s.points.get(4)));
							   shapes.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(0), s.points.get(1), s.points.get(2)));
							   shapes.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(2), s.points.get(3), s.points.get(4)));
							   shapes.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(4), s.points.get(5), s.points.get(0)));
							   if (s.depth + 1 < Integer.parseInt(subDepthBox.getText()) && triS) {
								   shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(0), s.points.get(2), s.points.get(4)));
								   shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(0), s.points.get(1), s.points.get(2)));
								   shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(2), s.points.get(3), s.points.get(4)));
								   shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(4), s.points.get(5), s.points.get(0)));
							   }
							   break;
						   case 1:
							   shapes.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(1), s.points.get(3), s.points.get(5)));
							   shapes.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(1), s.points.get(2), s.points.get(3)));
							   shapes.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(3), s.points.get(4), s.points.get(5)));
							   shapes.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(5), s.points.get(0), s.points.get(1)));
							   if (s.depth + 1 < Integer.parseInt(subDepthBox.getText()) && triS) {
								   shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(1), s.points.get(3), s.points.get(5)));
								   shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(1), s.points.get(2), s.points.get(3)));
								   shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(3), s.points.get(4), s.points.get(5)));
								   shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(5), s.points.get(0), s.points.get(1)));
							   }
							   break;
					   }
					   break;}
				case 1 : {//3-Way Split
					   pointData cen = midPoint(s.points.get(0), s.points.get(3));
					   switch(getRandomCase(2)) {
						   case 0:
							   shapes.add(new Shape(ShapeType.QUAD, s.depth + 1, s.points.get(0), s.points.get(1), s.points.get(2), cen));
							   shapes.add(new Shape(ShapeType.QUAD, s.depth + 1, s.points.get(2), s.points.get(3), s.points.get(4), cen));
							   shapes.add(new Shape(ShapeType.QUAD, s.depth + 1, s.points.get(4), s.points.get(5), s.points.get(0), cen));
							   // if (s.depth + 1 < Integer.parseInt(subDepthBox.getText())) {
							   //     shapesToSub.add(new Shape(ShapeType.QUAD, s.depth + 1, s.points.get(0), s.points.get(1), s.points.get(2), cen));
							   //     shapesToSub.add(new Shape(ShapeType.QUAD, s.depth + 1, s.points.get(2), s.points.get(3), s.points.get(4), cen));
							   //     shapesToSub.add(new Shape(ShapeType.QUAD, s.depth + 1, s.points.get(4), s.points.get(5), s.points.get(0), cen));
							   // }
							   break;
						   case 1:
							   shapes.add(new Shape(ShapeType.QUAD, s.depth + 1, s.points.get(1), s.points.get(2), s.points.get(3), cen));
							   shapes.add(new Shape(ShapeType.QUAD, s.depth + 1, s.points.get(3), s.points.get(4), s.points.get(5), cen));
							   shapes.add(new Shape(ShapeType.QUAD, s.depth + 1, s.points.get(5), s.points.get(0), s.points.get(1), cen));
							   // if (s.depth + 1 < Integer.parseInt(subDepthBox.getText())) {
							   //     shapesToSub.add(new Shape(ShapeType.QUAD, s.depth + 1 s.points.get(1), s.points.get(2), s.points.get(3), cen));
							   //     shapesToSub.add(new Shape(ShapeType.QUAD, s.depth + 1 s.points.get(3), s.points.get(4), s.points.get(5), cen));
							   //     shapesToSub.add(new Shape(ShapeType.QUAD, s.depth + 1 s.points.get(5), s.points.get(0), s.points.get(1), cen));
							   // }
							   break;
					   }
					   break;}
				case 2 : {//4-Way Split
					   pointData cen = midPoint(s.points.get(0), s.points.get(3));
					   switch(getRandomCase(3)) {
						   case 0:
							   shapes.add(new Shape(ShapeType.QUAD, s.depth + 1, s.points.get(0), s.points.get(1), s.points.get(2), cen));
							   shapes.add(new Shape(ShapeType.QUAD, s.depth + 1, s.points.get(3), s.points.get(4), s.points.get(5), cen));
							   shapes.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(2), s.points.get(3), cen));
							   shapes.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(5), s.points.get(0), cen));
							   if (s.depth + 1 < Integer.parseInt(subDepthBox.getText()) && triS) {
								   // shapesToSub.add(new Shape(ShapeType.QUAD, s.depth + 1, s.points.get(0), s.points.get(1), s.points.get(2), cen));
								   // shapesToSub.add(new Shape(ShapeType.QUAD, s.depth + 1, s.points.get(3), s.points.get(4), s.points.get(5), cen));
								   shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(2), s.points.get(3), cen));
								   shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(5), s.points.get(0), cen));
							   }
							   break;
						   case 1:
							   shapes.add(new Shape(ShapeType.QUAD, s.depth + 1, s.points.get(1), s.points.get(2), s.points.get(3), cen));
							   shapes.add(new Shape(ShapeType.QUAD, s.depth + 1, s.points.get(4), s.points.get(5), s.points.get(0), cen));
							   shapes.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(3), s.points.get(4), cen));
							   shapes.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(0), s.points.get(1), cen));
							   if (s.depth + 1 < Integer.parseInt(subDepthBox.getText()) && triS) {
								   // shapesToSub.add(new Shape(ShapeType.QUAD, s.depth + 1, s.points.get(1), s.points.get(2), s.points.get(3), cen));
								   // shapesToSub.add(new Shape(ShapeType.QUAD, s.depth + 1, s.points.get(4), s.points.get(5), s.points.get(0), cen));
								   shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(3), s.points.get(4), cen));
								   shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(0), s.points.get(1), cen));
							   }
							   break;
						   case 2:
							   shapes.add(new Shape(ShapeType.QUAD, s.depth + 1, s.points.get(2), s.points.get(3), s.points.get(4), cen));
							   shapes.add(new Shape(ShapeType.QUAD, s.depth + 1, s.points.get(5), s.points.get(0), s.points.get(1), cen));
							   shapes.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(4), s.points.get(5), cen));
							   shapes.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(1), s.points.get(2), cen));
							   if (s.depth + 1 < Integer.parseInt(subDepthBox.getText()) && triS) {
								   // shapesToSub.add(new Shape(ShapeType.QUAD, s.depth + 1, s.points.get(2), s.points.get(3), s.points.get(4), cen));
								   // shapesToSub.add(new Shape(ShapeType.QUAD, s.depth + 1, s.points.get(5), s.points.get(0), s.points.get(1), cen));
								   shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(4), s.points.get(5), cen));
								   shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(1), s.points.get(2), cen));
							   }
							   break;
					   }
					   break;}
				case 3 : {//6-Way Split
					   pointData cen = midPoint(s.points.get(0), s.points.get(3));
					   shapes.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(0), s.points.get(1), cen));
					   shapes.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(1), s.points.get(2), cen));
					   shapes.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(2), s.points.get(3), cen));
					   shapes.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(3), s.points.get(4), cen));
					   shapes.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(4), s.points.get(5), cen));
					   shapes.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(5), s.points.get(0), cen));
					   if (s.depth + 1 < Integer.parseInt(subDepthBox.getText()) && triS) {
						   shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(0), s.points.get(1), cen));
						   shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(1), s.points.get(2), cen));
						   shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(2), s.points.get(3), cen));
						   shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(3), s.points.get(4), cen));
						   shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(4), s.points.get(5), cen));
						   shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(5), s.points.get(0), cen));
					   }
					   break;}
				   case 4 : {//Half
					   switch(getRandomCase(3)) {
						   case 0:
							   shapes.add(new Shape(ShapeType.QUAD, s.depth + 1, s.points.get(0), s.points.get(1), s.points.get(2), s.points.get(3)));
							   shapes.add(new Shape(ShapeType.QUAD, s.depth + 1, s.points.get(3), s.points.get(4), s.points.get(5), s.points.get(0)));
							   // if (s.depth + 1 < Integer.parseInt(subDepthBox.getText())) {
							   //     shapesToSub.add(new Shape(ShapeType.QUAD, s.depth + 1, s.points.get(0), s.points.get(1), s.points.get(2), s.points.get(3)));
							   //     shapesToSub.add(new Shape(ShapeType.QUAD, s.depth + 1, s.points.get(3), s.points.get(4), s.points.get(5), s.points.get(0)));
							   // }
							   break;
						   case 1:
							   shapes.add(new Shape(ShapeType.QUAD, s.depth + 1, s.points.get(1), s.points.get(2), s.points.get(3), s.points.get(4)));
							   shapes.add(new Shape(ShapeType.QUAD, s.depth + 1, s.points.get(4), s.points.get(5), s.points.get(0), s.points.get(1)));
							   // if (s.depth + 1 < Integer.parseInt(subDepthBox.getText())) {
							   //     shapesToSub.add(new Shape(ShapeType.QUAD, s.depth + 1, s.points.get(1), s.points.get(2), s.points.get(3), s.points.get(4)));
							   //     shapesToSub.add(new Shape(ShapeType.QUAD, s.depth + 1, s.points.get(4), s.points.get(5), s.points.get(0), s.points.get(1)));
							   // }
							   break;
						   case 2:
							   shapes.add(new Shape(ShapeType.QUAD, s.depth + 1, s.points.get(2), s.points.get(3), s.points.get(4), s.points.get(5)));
							   shapes.add(new Shape(ShapeType.QUAD, s.depth + 1, s.points.get(5), s.points.get(0), s.points.get(1), s.points.get(2)));
							   // if (s.depth + 1 < Integer.parseInt(subDepthBox.getText())) {
							   //     shapesToSub.add(new Shape(ShapeType.QUAD, s.depth + 1, s.points.get(2), s.points.get(3), s.points.get(4), s.points.get(5)));
							   //     shapesToSub.add(new Shape(ShapeType.QUAD, s.depth + 1, s.points.get(5), s.points.get(0), s.points.get(1), s.points.get(2)));
							   // }
							   break;
					   }
					   break;}
				// case 5:{//Random Division
				//     ArrayList<Integer> points = new ArrayList<Integer>();
				//     for(int k = 0; k < 5; k++) {
				//         points.add(k);
				//     }
				//     int first = getRandomCase(points.size()+1);
				//     println("first,second");
				//     println(first);
				//     points.clear();
				//     for(int k = 0; k < 5; k++) {
				//         if (first != k && first-1 != k && first+1 != k && (first == 0? k != 5 : true) && (first == 5? k != 0 : true)) {
				//             points.add(k);
				//         }
				//     }
				//     int second = points.get(getRandomCase(points.size()));
				//     println(second);
				//     break;}
			}
		} else if (s.type == ShapeType.SQUARE) {
			ArrayList<Integer> subOptions = new ArrayList<Integer>();
			for (int j = 0; j < subsSquare.size(); j++) {
				if (subsSquare.get(j)) {
					   subOptions.add(j);
				   }
			}
			if (subOptions.size() <= 0) {
				continue;
			} else {
				// shapesToSub.remove(index);
			}
			int subIndex = getRandomCase(subOptions.size());
			switch(subOptions.get(subIndex)) {
				case 0 : {//Quarters
					   pointData topMid = midPoint(s.points.get(0), new pointData(s.points.get(1).x, s.points.get(0).y));
					   pointData leftMid = midPoint(s.points.get(0), new pointData(s.points.get(0).x, s.points.get(1).y));
					   pointData bottomMid = midPoint(s.points.get(1), new pointData(s.points.get(0).x, s.points.get(1).y));
					   pointData rightMid = midPoint(s.points.get(1), new pointData(s.points.get(1).x, s.points.get(0).y));
					   pointData mid = midPoint(s.points.get(0), s.points.get(1));
					   shapes.add(new Shape(ShapeType.SQUARE, s.depth + 1, s.points.get(0), mid));
					   shapes.add(new Shape(ShapeType.SQUARE, s.depth + 1, leftMid, bottomMid));
					   shapes.add(new Shape(ShapeType.SQUARE, s.depth + 1, mid, s.points.get(1)));
					   shapes.add(new Shape(ShapeType.SQUARE, s.depth + 1, topMid, rightMid));
			  			if (s.depth + 1 < Integer.parseInt(subDepthBox.getText()) && squS) {
						   shapesToSub.add(new Shape(ShapeType.SQUARE, s.depth + 1, s.points.get(0), mid));
						   shapesToSub.add(new Shape(ShapeType.SQUARE, s.depth + 1, leftMid, bottomMid));
						   shapesToSub.add(new Shape(ShapeType.SQUARE, s.depth + 1, mid, s.points.get(1)));
				 				shapesToSub.add(new Shape(ShapeType.SQUARE, s.depth + 1, topMid, rightMid));
				 			}
					   break;}
				   case 1 : {//Diagonal
					   pointData topRight = new pointData(s.points.get(1).x, s.points.get(0).y);
					   pointData botLeft = new pointData(s.points.get(0).x, s.points.get(1).y);
					   pointData mid = midPoint(s.points.get(0), s.points.get(1));
					   shapes.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(0), topRight, mid));
					   shapes.add(new Shape(ShapeType.TRI, s.depth + 1, topRight, s.points.get(1), mid));
					   shapes.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(1), botLeft, mid));
					   shapes.add(new Shape(ShapeType.TRI, s.depth + 1, botLeft, s.points.get(0), mid));
			  			if (s.depth + 1 < Integer.parseInt(subDepthBox.getText()) && triS) {
						   shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(0), topRight, mid));
						   shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1, topRight, s.points.get(1), mid));
						   shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(1), botLeft, mid));
				 				shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1, botLeft, s.points.get(0), mid));
				 			}
					   break;}
				case 2 : {//Half split
					   pointData topMid = midPoint(s.points.get(0), new pointData(s.points.get(1).x, s.points.get(0).y));
					   pointData leftMid = midPoint(s.points.get(0), new pointData(s.points.get(0).x, s.points.get(1).y));
					   pointData bottomMid = midPoint(s.points.get(1), new pointData(s.points.get(0).x, s.points.get(1).y));
					   pointData rightMid = midPoint(s.points.get(1), new pointData(s.points.get(1).x, s.points.get(0).y));
					   switch(getRandomCase(2)) {
						   case 0:
							   shapes.add(new Shape(ShapeType.SQUARE, s.depth + 1, s.points.get(0), bottomMid));
							   shapes.add(new Shape(ShapeType.SQUARE, s.depth + 1, topMid, s.points.get(1)));
							   if (s.depth + 1 < Integer.parseInt(subDepthBox.getText()) && squS) {
								   shapesToSub.add(new Shape(ShapeType.SQUARE, s.depth + 1, s.points.get(0), bottomMid));
								   shapesToSub.add(new Shape(ShapeType.SQUARE, s.depth + 1, topMid, s.points.get(1)));
							   }
							   break;
						   case 1:
							   shapes.add(new Shape(ShapeType.SQUARE, s.depth + 1, s.points.get(0), rightMid));
							   shapes.add(new Shape(ShapeType.SQUARE, s.depth + 1, leftMid, s.points.get(1)));
							   if (s.depth + 1 < Integer.parseInt(subDepthBox.getText()) && squS) {
								   shapesToSub.add(new Shape(ShapeType.SQUARE, s.depth + 1, s.points.get(0), rightMid));
								   shapesToSub.add(new Shape(ShapeType.SQUARE, s.depth + 1, leftMid, s.points.get(1)));
							   }
							   break;
					   }
					   break;}
				case 3 : {//Inscribe diamond
					   pointData topMid = midPoint(s.points.get(0), new pointData(s.points.get(1).x, s.points.get(0).y));
					   pointData leftMid = midPoint(s.points.get(0), new pointData(s.points.get(0).x, s.points.get(1).y));
					   pointData bottomMid = midPoint(s.points.get(1), new pointData(s.points.get(0).x, s.points.get(1).y));
					   pointData rightMid = midPoint(s.points.get(1), new pointData(s.points.get(1).x, s.points.get(0).y));
					   pointData topRight = new pointData(s.points.get(1).x, s.points.get(0).y);
					   pointData botLeft = new pointData(s.points.get(0).x, s.points.get(1).y);
					   shapes.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(0), topMid, leftMid));
					   shapes.add(new Shape(ShapeType.TRI, s.depth + 1, topMid, topRight, rightMid));
					   shapes.add(new Shape(ShapeType.TRI, s.depth + 1, rightMid, s.points.get(1), bottomMid));
					   shapes.add(new Shape(ShapeType.TRI, s.depth + 1, bottomMid, botLeft, leftMid));
					   shapes.add(new Shape(ShapeType.QUAD, s.depth + 1, topMid, rightMid, bottomMid, leftMid));
			  			if (s.depth + 1 < Integer.parseInt(subDepthBox.getText()) && triS) {
						   shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1, s.points.get(0), topMid, leftMid));
						   shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1, topMid, topRight, rightMid));
						   shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1, rightMid, s.points.get(1), bottomMid));
						   shapesToSub.add(new Shape(ShapeType.TRI, s.depth + 1, bottomMid, botLeft, leftMid));
				 				// shapesToSub.add(new Shape(ShapeType.QUAD, s.depth + 1, topMid, rightMid, bottomMid, leftMid);
				 			}
					   break;}
			   }
		}
	}
}

void genColors(int count) {
	colors.clear();
	
	startHue = round(startHue);
	startSat = round(startSat);
	startBri = round(startBri);
	colors.add(color(startHue >= 0 ? startHue : random(0,360), startSat >= 0 ? startSat : random(0, 100), startBri >= 0 ? startBri : random(0,100)));
	
	float spacingH;
	if (count != 0) {
		spacingH = 360 / count;
	} else {
		spacingH = 360;
	}
	
	float iHue = hue(colors.get(0));
	float hueCurrent = iHue;
	float iSat = saturation(colors.get(0));
	float satCurrent = iSat;
	float iBri = brightness(colors.get(0));
	float briCurrent = iBri;
	
	switch(mode) {
		case 0 : //Intermediate
			for (int i = 1; i < count; i++) {
				hueCurrent = iHue + i * spacingH;
				while(hueCurrent > 360) {
					   hueCurrent -= 360;
				   }
				satCurrent = iSat - i * satSpacing;
				while(satCurrent < 0) {
					   satCurrent += 100;
				   }
				briCurrent = iBri - i * briSpacing;
				while(briCurrent < 0) {
					   briCurrent += 100;
				   }
				colors.add(color(hueCurrent, satCurrent, briCurrent));
			}
			break;
		case 1 : //Analogous
			for (int i = 1; i < count; i++) {
				hueCurrent = iHue + i * round(hueSpacing);
				while(hueCurrent > 360) {
					   hueCurrent -= 360;
				   }
				satCurrent = iSat - i * satSpacing;
				while(satCurrent < 0) {
					   satCurrent += 100;
				   }
				briCurrent = iBri - i * briSpacing;
				while(briCurrent < 0) {
					   briCurrent += 100;
				   }
				colors.add(color(hueCurrent, satCurrent, briCurrent));
			}
			break;
		case 2 : //Shades
			for (int i = 1; i < count; i++) {
				briCurrent = iBri - i * briSpacing;
				while(briCurrent < 0) {
					   briCurrent += 100;
				   }
				satCurrent = iSat - i * satSpacing;
				while(satCurrent < 0) {
					   satCurrent += 100;
				   }
				colors.add(color(hueCurrent, satCurrent, briCurrent));
			}
			break;
		case 3 : //Monochromatic
			for (int i = 1; i < count; i++) {
				satCurrent = iSat - i * satSpacing;
				while(satCurrent < 0) {
					   satCurrent += 100;
				   }
				briCurrent = iBri - i * briSpacing;
				while(briCurrent < 0) {
					   briCurrent += 100;
				   }
				colors.add(color(hueCurrent, satCurrent, briCurrent));
			}
			break;
		case 4 : //Complimentary
			for (int i = 1; i < count; i++) {
				hueCurrent = iHue + i * 180;
				while(hueCurrent > 360) {
					   hueCurrent -= 360;
				   }
				satCurrent = iSat - i * satSpacing;
				while(satCurrent < 0) {
					   satCurrent += 100;
				   }
				briCurrent = iBri - i * briSpacing;
				while(briCurrent < 0) {
					   briCurrent += 100;
				   }
				colors.add(color(hueCurrent, satCurrent, briCurrent));
			}
			break;
		case 5 : //Left Complimentary
			for (int i = 1; i < count; i++) {
				hueCurrent = iHue + (i % 2 == 1 ? 150 : 0);
				while(hueCurrent > 360) {
					   hueCurrent -= 360;
				   }
				satCurrent = iSat - i * satSpacing;
				while(satCurrent < 0) {
					   satCurrent += 100;
				   }
				briCurrent = iBri - i * briSpacing;
				while(briCurrent < 0) {
					   briCurrent += 100;
				   }
				colors.add(color(hueCurrent, satCurrent, briCurrent));
			}
			break;
		case 6 : //Right Complimentary
			for (int i = 1; i < count; i++) {
				hueCurrent = iHue + (i % 2 == 1 ? 210 : 0);
				while(hueCurrent > 360) {
					   hueCurrent -= 360;
				   }
				satCurrent = iSat - i * satSpacing;
				while(satCurrent < 0) {
					   satCurrent += 100;
				   }
				briCurrent = iBri - i * briSpacing;
				while(briCurrent < 0) {
					   briCurrent += 100;
				   }
				colors.add(color(hueCurrent, satCurrent, briCurrent));
			}
			break;
		case 7 : //Split Complimentary
			for (int i = 1; i < count; i++) {
				hueCurrent = iHue + (i % 3 == 1 ? 150 : i % 3 == 2 ? 210 : 0);
				while(hueCurrent > 360) {
					   hueCurrent -= 360;
				   }
				satCurrent = iSat - i * satSpacing;
				while(satCurrent < 0) {
					   satCurrent += 100;
				   }
				briCurrent = iBri - i * briSpacing;
				while(briCurrent < 0) {
					   briCurrent += 100;
				   }
				colors.add(color(hueCurrent, satCurrent, briCurrent));
			}
			break;
		case 8 : //Triad
			for (int i = 1; i < count; i++) {
				hueCurrent = iHue + i * 120;
				while(hueCurrent > 360) {
					   hueCurrent -= 360;
				   }
				satCurrent = iSat - i * satSpacing;
				while(satCurrent < 0) {
					   satCurrent += 100;
				   }
				briCurrent = iBri - i * briSpacing;
				while(briCurrent < 0) {
					   briCurrent += 100;
				   }
				colors.add(color(hueCurrent, satCurrent, briCurrent));
			}
			break;
		case 9 : //Tetrad
			for (int i = 1; i < count; i++) {
				hueCurrent = iHue + i * 90;
				while(hueCurrent > 360) {
					   hueCurrent -= 360;
				   }
				satCurrent = iSat - i * satSpacing;
				while(satCurrent < 0) {
					   satCurrent += 100;
				   }
				briCurrent = iBri - i * briSpacing;
				while(briCurrent < 0) {
					   briCurrent += 100;
				   }
				colors.add(color(hueCurrent, satCurrent, briCurrent));
			}
			break;
		case 10 : //Pentagram
			for (int i = 1; i < count; i++) {
				hueCurrent = iHue + i * 72;
				while(hueCurrent > 360) {
					   hueCurrent -= 360;
				   }
				satCurrent = iSat - i * satSpacing;
				while(satCurrent < 0) {
					   satCurrent += 100;
				   }
				briCurrent = iBri - i * briSpacing;
				while(briCurrent < 0) {
					   briCurrent += 100;
				   }
				colors.add(color(hueCurrent, satCurrent, briCurrent));
			}
			break;
		case 11 : //Compound Left
			for (int i = 1; i < count; i++) {
				hueCurrent = iHue + (i % 4 == 1 ? 150 : i % 4 == 2 ? 120 : i % 4 == 3 ? 60 : 0);
				while(hueCurrent > 360) {
					   hueCurrent -= 360;
				   }
				satCurrent = iSat - i * satSpacing;
				while(satCurrent < 0) {
					   satCurrent += 100;
				   }
				briCurrent = iBri - i * briSpacing;
				while(briCurrent < 0) {
					   briCurrent += 100;
				   }
				colors.add(color(hueCurrent, satCurrent, briCurrent));
			}
			break;
		case 12 : //Compound Right
			for (int i = 1; i < count; i++) {
				hueCurrent = iHue + (i % 4 == 1 ? 210 : i % 4 == 2 ? 240 : i % 4 == 3 ? 300 : 0);
				while(hueCurrent > 360) {
					   hueCurrent -= 360;
				   }
				satCurrent = iSat - i * satSpacing;
				while(satCurrent < 0) {
					   satCurrent += 100;
				   }
				briCurrent = iBri - i * briSpacing;
				while(briCurrent < 0) {
					   briCurrent += 100;
				   }
				colors.add(color(hueCurrent, satCurrent, briCurrent));
			}
			break;
	}
}

color rColor(Shape shape) {
	color c = colors.get(int(random(0,colors.size())));
	switch(noiseMode) {
		case 1 : //Color Mode
			return colors.get(int(noise(shape.midpoint().x * perlinScale, shape.midpoint().y * perlinScale) * colors.size()));
		case 2 : //Brightnes Tint Mode
			return color(hue(c), saturation(c), noise(shape.midpoint().x * perlinScale, shape.midpoint().y * perlinScale) * 100);
		case 3 : //Saturation Tint Mode
			return color(hue(c), noise(shape.midpoint().x * perlinScale, shape.midpoint().y * perlinScale) * 100, brightness(c));
		default:
			return c;
	}
}

color rColor(pointData point) {
	color c = colors.get(int(random(0,colors.size())));
	switch(noiseMode) {
		case 1 : //Color Mode
			return colors.get(int(noise(point.x * perlinScale, point.y * perlinScale) * colors.size()));
			case 2 : //Brightnes Tint Mode
			return color(hue(c), saturation(c), noise(point.x * perlinScale, point.y * perlinScale) * 100);
			case 3 : //Saturation Tint Mode
			return color(hue(c), noise(point.x * perlinScale, point.y * perlinScale) * 100, brightness(c));
			default:
			return c;
	}
}

color rColor() {
	return colors.get(int(random(0,colors.size())));
}

void goBack() {
	undoAmount++;
	if (prevSeeds.size() - undoAmount >= 0) {
		seedBox.setText(prevSeeds.get(prevSeeds.size() - undoAmount));
		drawPlane();
	}
}

void keyReleased() {
	if (key == CODED && (keyCode == 157 || keyCode == CONTROL) && modPressed) {
		modPressed = false;
	} else if ((key == 'c' || keyCode == 67) && cPressed) {
		cPressed = false;
	} else  if ((key == 'v' || keyCode == 86) && vPressed) {
		vPressed = false;
	}
}

void keyPressed() {
	if (key == CODED && (keyCode == 157 || keyCode == CONTROL) && !modPressed) {
		modPressed = true;
	} else if ((key == 'c' || keyCode == 67) && !cPressed) {
		cPressed = true;
	} else  if ((key == 'v' || keyCode == 86) && !vPressed) {
		vPressed = true;
	}
	
	if (key == CODED) {
		if (keyCode == UP) {
			imageSaveCount = loadStrings(docsPath + "ShapePlane/imageSaveCount.txt");
			if (guiState) {
				toggleGUI(false);
				drawPlane();
				if (!trial) {
					   endRecord();
				   } else {
					   save(docsPath + "ShapePlane/images/ShapePlane-" + int(imageSaveCount[0]) + ".jpg");
				   }
				savePrefsPath(docsPath + "ShapePlane/images/ShapePlane-" + int(imageSaveCount[0]) + "-PRESET");
				toggleGUI(true);
			} else {
				if (!trial) {
					   endRecord();
				   } else {
					   save(docsPath + "ShapePlane/images/ShapePlane-" + int(imageSaveCount[0]) + ".jpg");
				   }
				savePrefsPath(docsPath + "ShapePlane/images/ShapePlane-" + int(imageSaveCount[0]) + "-PRESET");
			}
			saveStrings(docsPath + "ShapePlane/imageSaveCount.txt", new String[] {"" + (int(imageSaveCount[0]) + 1)});
		} else if (keyCode == LEFT) {
			toggleGUI(!guiState);
			if (!guiState) {
				drawPlane();
			}
		} else if (keyCode == RIGHT) {
			seedBox.setText("");
			if (ranPerlin) {
				randomizePerlinSeed();
			}
			drawPlane();
		} else if (keyCode == DOWN) {
			goBack();
		}
	} else if (key == TAB && guiState) {
		if (currentBoxNum < 0) {
			boxesVis.get(0).setFocus(true);
		} else if (currentBoxNum >= boxesVis.size() - 1) {
			boxesVis.get(boxesVis.size() - 1).setFocus(false);
		} else {
			boxesVis.get(currentBoxNum).setFocus(false);
			boxesVis.get(currentBoxNum + 1).setFocus(true);
		}
	} else if (key == ESC) {
		key = 0;
		clearEmptyFiles();
		exit();
	}
}

void controlEvent(ControlEvent event) {
	if (event.isTab()) {
		cp5.getGroup("allTabs").setTab(event.getTab());
		drawPlane();
		toggleGUI(true);
	}
}

void toggleGUI(boolean state) {
	if (state) {
		raster = get();
		fill(0, 70);
		noStroke();
		rect(0, 0, width, height);
		cp5.show();
		previewGUIReset = false;
	} else {
		cp5.hide();
	}
	for (Textfield t : boxes) {
		t.setFocus(false);
	}
	guiState = state;
}

void setListOptions(ListBox list, Integer[] indexes) {
	for (int i = 0; i < list.getItems().size(); i++) {
		list.getItem(i).put("state", false);
	}
	for (int in : indexes) {
		list.getItem(in).put("state", true);
	}
}

void randomizePerlinSeed() {
	perlinSeed = "" + int(unaffectedRandomRange(0, 999999999));
	while(perlinSeed.length() < 10) {
		perlinSeed = "0" + perlinSeed;
	}
	perlinSeedBox.setText(perlinSeed);
	noiseSeed(perlinSeed.hashCode());
}

void minMaxLock(Slider minS, Slider maxS) {
	if (minS.getValue() > maxS.getValue() && minS.isInside()) {
		maxS.setValue(minS.getValue());
	} else if (maxS.getValue() < minS.getValue() && maxS.isInside()) {
		minS.setValue(maxS.getValue());
	}
}

void loneBoxManage(Textfield box) {
	for (int i = 0; i < boxesVis.size(); i++) {
		if (boxesVis.get(i) == box) {
			if (box.isFocus()) {
				currentBoxNum = i;
			} else if (currentBoxNum == i) {
				currentBoxNum = -1;
			}
		}
	}
	if (box.isFocus()) {
		if (cPressed && modPressed) {
		   box.setFocus(false);
		   String t = (box.getText().substring(box.getText().length() - 1).toLowerCase().compareTo("c") != 0 && box.getText().substring(box.getText().length() - 1).toLowerCase().compareTo("") != 0) ? box.getText() : box.getText().substring(0, box.getText().length() - 1);
		   copyString(t);
		   box.setText(t);
		} else if (vPressed && modPressed) {
		   box.setText(pasteString());
		}
	}
}

float boxSliderBalance(float value, Textfield box, Slider slider, int decimals) {
	String s = String.format("%." + decimals + "f", slider.getValue()) + "";
	
	for (int i = 0; i < boxesVis.size(); i++) {
		if (boxesVis.get(i) == box) {
			if (box.isFocus()) {
				currentBoxNum = i;
			} else if (currentBoxNum == i) {
				currentBoxNum = -1;
			}
		}
	}
	
	if (!box.isFocus()) {
		box.setText(s);
	} else if (box.isFocus()) {
		if (keyPressed && key == 10) {
			box.setFocus(false);
			box.setText(s);
		} else if (keyPressed && key == 'c' && modPressed) {
			box.setFocus(false);
			String t = (box.getText().substring(box.getText().length() - 1).toLowerCase().compareTo("c") != 0) ? box.getText() : box.getText().substring(0, box.getText().length() - 1);
			copyString(t);
			box.setText(t);
		} else if (keyPressed && key == 'v' && modPressed) {
			box.setText(pasteString());
			slider.setValue(float(pasteString()));
		} else if (keyPressed) {
			slider.setValue(float(box.getText()));
		}
	}
	return float(box.getText());
}

void updateColorPickers() {
	startHueSlider.setColorForeground(color(startHue, 100, 100)).setColorActive(color(startHue, 100, 100));
	startSatSlider.setColorForeground(color(startHue, startSat, 100)).setColorActive(color(startHue, startSat, 100));
	startBriSlider.setColorForeground(color(startHue, 100, startBri)).setColorActive(color(startHue, 100, startBri));
	
	strokeHueSlider.setColorForeground(color(strokeHue, 100, 100)).setColorActive(color(strokeHue, 100, 100));
	strokeSatSlider.setColorForeground(color(strokeHue, strokeSat, 100)).setColorActive(color(strokeHue, strokeSat, 100));
	strokeBriSlider.setColorForeground(color(strokeHue, 100, strokeBri)).setColorActive(color(strokeHue, 100, strokeBri));
}

void updatePresetList() {
	File dir = new File(docsPath + "ShapePlane/presets");
	presetList.clear();
	if (!dir.exists()) {
		dir.mkdir();
	} else if (dir.listFiles() != null) {
		File[] files = dir.listFiles();
		for (int i = 0; i < files.length; i++) {
			presetList.addItems(new String[] {stripExtension(files[i].getName())});
		}
	}
}

float withinLoopBounds(float initial, float max) {
	float i = initial;
	while(i > max) {
		i -= max;
	}
	return i;
}

String stripExtension(String fileString) {
	return fileString.replace(".txt", "");
}

void updateColorPreview() {
	if (cp5.getTab("Color").isActive()) {
		for (Button b : colorPreviews) {
		b.remove();
	}
		colorPreviews.clear();
		fill(0);
		noStroke();
		rect(0, height - 120, width, height);
		genColors(round(colorCount));
		float wid;
		if (round(colorCount) != 0) {
			wid = width / colorCount;
		} else {
			wid = width;
		}
		for (int i = 0; i < colors.size(); i++) {
			fill(colors.get(int(i)));
			rect(i * wid, height - 90, i * wid + wid, height);
		Button but = cp5.addButton("b" + i).setPosition(i * wid, height - 90).setSize(int(wid),90).setCaptionLabel("").setColorActive(colors.get(i)).setColorBackground(colors.get(i)).setColorForeground(colors.get(i)).setTab("Color");
		colorPreviews.add(but);
		}
	}
}

void copyString(String string) {
	Clipboard clipboard = Toolkit.getDefaultToolkit().getSystemClipboard();
	StringSelection strSel = new StringSelection(string);
	clipboard.setContents(strSel, null);
}

String pasteString() {
	String str = "";
	try {
		str = (String)Toolkit.getDefaultToolkit().getSystemClipboard().getData(DataFlavor.stringFlavor);
	} catch(Exception e) {
		println(e);
	}
	return str;
}

void savePrefs() {
	String st = presetSaveNameBox.getText();
	if (lpShape == 0 || lpShape == 4 || lpShape == 5) { //Triangle
		subsTri.clear();
		for (int i = 0; i < subList.getItems().size(); i++) {
			subsTri.add((boolean)subList.getItem(i).get("state"));
		}
	} else if (lpShape == 1) { //Hexagon
		subsHex.clear();
		for (int i = 0; i < subList.getItems().size(); i++) {
			subsHex.add((boolean)subList.getItem(i).get("state"));
		}
	} else if (lpShape == 2 || lpShape == 3) { //Square
		subsSquare.clear();
		for (int i = 0; i < subList.getItems().size(); i++) {
			subsSquare.add((boolean)subList.getItem(i).get("state"));
		}
	}
	String subsTriTemp = "";
	for (boolean b : subsTri) {
		subsTriTemp += (b + ",");
	}
	subsTriTemp = subsTriTemp.substring(0, subsTriTemp.length() - 1);
	String subsHexTemp = "";
	for (boolean b : subsHex) {
		subsHexTemp += (b + ",");
	}
	subsHexTemp = subsHexTemp.substring(0, subsHexTemp.length() - 1);
	String subsSquareTemp = "";
	for (boolean b : subsSquare) {
		subsSquareTemp += (b + ",");
	}
	subsSquareTemp = subsSquareTemp.substring(0, subsSquareTemp.length() - 1);
	saveStrings(docsPath + "ShapePlane/presets/" + (st.compareTo("") == 0 ? "newPreset" : st) + ".txt", new String[] {"" + (int)size + "\n" + (int)colorCount + "\n" + (int)hueSpacing + "\n" + (int)mode + "\n" +
	   (int)startHue + "\n" + (int)startSat + "\n" + (int)startBri + "\n" + (int)shape + "\n" + strokeWidth + "\n" + (int)strokeHue + "\n" + (int)strokeSat + "\n" + (int)strokeBri + "\n" +
			sub + "\n" + (int)subCount + "\n" + (int)subDepth + "\n" + (int)noiseMode + "\n" + perlinSeed + "\n" + (float)perlinScale + "\n" + ranPerlin + "\n" + shadowAngle + "\n" + shadowIntensity + "\n" +
	   (int)satSpacing + "\n" + (int)briSpacing + "\n" + subsTriTemp + "\n" + subsHexTemp + "\n" + subsSquareTemp + "\n" + seed + "\n"});
	updatePresetList();
}

void savePrefsPath(String path) {
	if (lpShape == 0 || lpShape == 4 || lpShape == 5) { //Triangle
		subsTri.clear();
		for (int i = 0; i < subList.getItems().size(); i++) {
			subsTri.add((boolean)subList.getItem(i).get("state"));
		}
	} else if (lpShape == 1) { //Hexagon
		subsHex.clear();
		for (int i = 0; i < subList.getItems().size(); i++) {
			subsHex.add((boolean)subList.getItem(i).get("state"));
		}
	} else if (lpShape == 2 || lpShape == 3) { //Square
		subsSquare.clear();
		for (int i = 0; i < subList.getItems().size(); i++) {
			subsSquare.add((boolean)subList.getItem(i).get("state"));
		}
	}
	String subsTriTemp = "";
	for (boolean b : subsTri) {
		subsTriTemp += (b + ",");
	}
	subsTriTemp = subsTriTemp.length() == 0 ? "" : subsTriTemp.substring(0, subsTriTemp.length() - 1);
	String subsHexTemp = "";
	for (boolean b : subsHex) {
		subsHexTemp += (b + ",");
	}
	subsHexTemp = subsHexTemp.length() == 0 ? "" : subsHexTemp.substring(0, subsHexTemp.length() - 1);
	String subsSquareTemp = "";
	for (boolean b : subsSquare) {
		subsSquareTemp += (b + ",");
	}
	subsSquareTemp = subsSquareTemp.length() == 0 ? "" : subsSquareTemp.substring(0, subsSquareTemp.length() - 1);
	saveStrings(path + ".txt", new String[] {"" + (int)size + "\n" + (int)colorCount + "\n" + (int)hueSpacing + "\n" + (int)mode + "\n" +
	   (int)startHue + "\n" + (int)startSat + "\n" + (int)startBri + "\n" + (int)shape + "\n" + strokeWidth + "\n" + (int)strokeHue + "\n" + (int)strokeSat + "\n" + (int)strokeBri + "\n" +
			sub + "\n" + (int)subCount + "\n" + (int)subDepth + "\n" + (int)noiseMode + "\n" + perlinSeed + "\n" + (float)perlinScale + "\n" + ranPerlin + "\n" + shadowAngle + "\n" + shadowIntensity + "\n" +
	   (int)satSpacing + "\n" + (int)briSpacing + "\n" + subsTriTemp + "\n" + subsHexTemp + "\n" + subsSquareTemp + "\n" + seed + "\n"});
	updatePresetList();
}

void loadPrefs() {
	if (!presetList.getItems().isEmpty()) {
		prefs = loadStrings(docsPath + "ShapePlane/presets/" + presetList.getItem(preset).entrySet().toArray()[3].toString().replace("text=", "") + ".txt");
		sizeSlider.setValue(int(prefs[0]));
		colorCountSlider.setValue(int(prefs[1]));
		hueSpacingSlider.setValue(int(prefs[2]));
		setListOptions(modeList, new Integer[] {int(prefs[3])});
		startHueSlider.setValue(int(prefs[4]));
		startSatSlider.setValue(int(prefs[5]));
		startBriSlider.setValue(int(prefs[6]));
		setListOptions(shapeList, new Integer[] {int(prefs[7])});
		strokeWidthSlider.setValue(float(prefs[8]));
		strokeHueSlider.setValue(int(prefs[9]));
		strokeSatSlider.setValue(int(prefs[10]));
		strokeBriSlider.setValue(int(prefs[11]));
		subToggle.setValue(boolean(prefs[12]));
		subCountSlider.setValue(int(prefs[13]));
		subDepthSlider.setValue(int(prefs[14]));
		setListOptions(noiseList, new Integer[] {int(prefs[15])});
		perlinSeedBox.setText(prefs[16]);
		perlinScaleSlider.setValue(float(prefs[17]));
		perlinRandomizeToggle.setValue(boolean(prefs[18]));
		shadowAngleSlider.setValue(int(prefs[19]));
		shadowIntensitySlider.setValue(float(prefs[20]));
		satSpacingSlider.setValue(int(prefs[21]));
		briSpacingSlider.setValue(int(prefs[22]));
		String[] subsTriTemp = prefs[23].split(",");
		subsTri.clear();
		for (String str : subsTriTemp) {
			subsTri.add(boolean(str));
		}
		String[] subsHexTemp = prefs[24].split(",");
		subsHex.clear();
		for (String str : subsHexTemp) {
			subsHex.add(boolean(str));
		}
		String[] subsSquareTemp = prefs[25].split(",");
		subsSquare.clear();
		for (String str : subsSquareTemp) {
			subsSquare.add(boolean(str));
		}
		refreshSubs();
		seedBox.setText(prefs[26]);
	}
}

void delPrefs() {
	File file = new File(docsPath + "ShapePlane/presets/" + presetList.getItem(preset).entrySet().toArray()[3].toString().replace("text=", "") + ".txt");
	if (file.exists()) {
		file.delete();
	}
	updatePresetList();
}

void loadDefault() {
	sizeSlider.setValue(int(defaultPrefs[0]));
	colorCountSlider.setValue(int(defaultPrefs[1]));
	hueSpacingSlider.setValue(int(defaultPrefs[2]));
	setListOptions(modeList, new Integer[] {int(defaultPrefs[3])});
	startHueSlider.setValue(int(defaultPrefs[4]));
	startSatSlider.setValue(int(defaultPrefs[5]));
	startBriSlider.setValue(int(defaultPrefs[6]));
	setListOptions(shapeList, new Integer[] {int(defaultPrefs[7])});
	strokeWidthSlider.setValue(float(defaultPrefs[8]));
	strokeHueSlider.setValue(int(defaultPrefs[9]));
	strokeSatSlider.setValue(int(defaultPrefs[10]));
	strokeBriSlider.setValue(int(defaultPrefs[11]));
	subToggle.setValue(boolean(defaultPrefs[12]));
	subCountSlider.setValue(int(defaultPrefs[13]));
	subDepthSlider.setValue(int(defaultPrefs[14]));
	setListOptions(noiseList, new Integer[] {int(defaultPrefs[15])});
	perlinSeedBox.setText(defaultPrefs[16]);
	perlinScaleSlider.setValue(float(defaultPrefs[17]));
	perlinRandomizeToggle.setValue(boolean(defaultPrefs[18]));
	shadowAngleSlider.setValue(int(defaultPrefs[19]));
	shadowIntensitySlider.setValue(float(defaultPrefs[20]));
	satSpacingSlider.setValue(int(defaultPrefs[21]));
	briSpacingSlider.setValue(int(defaultPrefs[22]));
	String[] subsTriTemp = defaultPrefs[23].split(",");
	subsTri.clear();
	for (String str : subsTriTemp) {
		subsTri.add(boolean(str));
	}
	String[] subsHexTemp = defaultPrefs[24].split(",");
	subsHex.clear();
	for (String str : subsHexTemp) {
		subsHex.add(boolean(str));
	}
	String[] subsSquareTemp = defaultPrefs[25].split(",");
	subsSquare.clear();
	for (String str : subsSquareTemp) {
		subsSquare.add(boolean(str));
	}
	refreshSubs();
}

boolean getRandomBoolean() {
	return random(0,1.0001) < 0.5;
}

int getRandomCase(int cases) {
	return int(random(0, cases));
}

void clearEmptyFiles() {
	File dir = new File(docsPath + "ShapePlane/images");
	
	if (!dir.exists()) {
		dir.mkdir();
	}
	
	File[] files = dir.listFiles();
	if (files != null) {
		for (File f : files) {
			if (f.length() == 0) {
				f.delete();
			}
		}
	}
}

float unaffectedRandomRange(float min, float max) {
	float range = max - min;
	return(float)(Math.random() * range + min);
}

void drawPoly(Shape s) {
	beginShape();
	if (s.points.size() == 2) { //Assume 2 points => square
		vertex(s.points.get(0).x,s.points.get(0).y);
		vertex(s.points.get(1).x,s.points.get(0).y);
		vertex(s.points.get(1).x,s.points.get(1).y);
		vertex(s.points.get(0).x,s.points.get(1).y);
	} else {
		for (pointData p : s.points)
			vertex(p.x, p.y);
	}
	endShape(CLOSE);
}

pointData midPoint(pointData a, pointData b) {
	return new pointData((a.x + b.x) / 2,(a.y + b.y) / 2);
}

pointData midPoint(pointData[] points) {
	float midX, midY;
	midX = midY = 0;
	for (pointData p : points) {
		midX += p.x;
		midY += p.y;
	}
	return new pointData(midX / points.length, midY / points.length);
}

public class pointData {
	float x, y;
	
	public pointData(float xVal, float yVal) {
		x = xVal;
		y = yVal;
	}
}

public class Shape {
	public ShapeType type;
	public int depth;
	// public pointData one, two, three, four, five, six, midPoint;
	public ArrayList<pointData> points;

	public Shape(Shape s) {
		this.type = s.type;
		this.depth = s.depth;
		this.points = new ArrayList<pointData>();
		this.points.addAll(s.points);
	}

	public Shape(ShapeType type, pointData... points) {
		this.type = type;
		this.depth = 0;
		this.points = new ArrayList<pointData>();
		for (pointData p : points) {
			this.points.add(p); 
		}
	}

	public Shape(ShapeType type, int depth, pointData... points) {
		this.type = type;
		this.depth = depth;
		this.points = new ArrayList<pointData>();
		for (pointData p : points) {
			this.points.add(p); 
		}
	}

	public pointData midpoint() {
		pointData[] arr = (pointData[])this.points.toArray();
		return midPoint(arr);
	}
}
