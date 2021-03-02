//IMPORT
import processing.pdf.*;

import controlP5.*;

import java.io.*;
import java.util.*;
import java.awt.Toolkit;
import java.awt.datatransfer.*;
import java.awt.Desktop;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.Socket;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.GregorianCalendar;
import java.util.TimeZone;
import java.net.UnknownHostException;

import com.dropbox.core.*;
import com.dropbox.core.DbxException;
import com.dropbox.core.DbxRequestConfig;
import com.dropbox.core.v2.DbxClientV2;
import com.dropbox.core.v2.files.FileMetadata;
import com.dropbox.core.v2.files.ListFolderResult;
import com.dropbox.core.v2.files.ListFolderErrorException;
import com.dropbox.core.v2.files.Metadata;
import com.dropbox.core.v2.users.FullAccount;
//DECLARE
ArrayList<Integer> colors = new ArrayList<Integer>();
float size, colorCount, lpColorCount, hueSpacing, lpHueSpacing, satSpacing, lpSatSpacing, briSpacing, lpBriSpacing, s3, strokeWidth, perlinScale, shadowIntensity;
int xCount, yCount, currentBoxNum, mode, lpMode, startHue, startSat, startBri, startAlp, lpHue, lpSat, lpBri, shape, lpShape, preset, undoAmount, subCount, subDepth, strokeHue, strokeSat, strokeBri, rotateMin, rotateMax, noiseMode, shadowAngle;
String seed, perlinSeed, os, licensePath, docsPath;
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

public static final String[] atomicTimeServers = new String[] {"129.6.15.30", "129.6.15.28", "132.163.97.1", "132.163.97.2", "132.163.96.1", "128.138.140.44"};
public static final int atomicTimePort = 13;

DbxRequestConfig config2;
DbxClientV2 client2;
private static final String token2 = "TOKEN OMITTED"; //Omitted dropbox token for security - it is not needed in this public version anyway.

void setup() {
    //INITIALIZE
    size(1000, 1000);
    frameRate(5000);

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

    config2 = new DbxRequestConfig("dropbox/LSys", "en_US");
    client2 = new DbxClientV2(config2, token2);
    os = getOS();
    if (os.compareTo("mac") == 0) {
    	licensePath = (new File(sketchPath(""))).getParentFile().getPath() + "/GenerativeLauncher.app/Contents/Java/data/license.txt";
    } else {
        licensePath = (new File(sketchPath(""))).getParentFile().getPath() + "/data/license.txt";
    }
    docsPath = System.getProperty("user.home") + File.separator + "Documents" + File.separator;
    trial = false;
    //if (!licenseCheckup()) { //Comment out to disable licence lookup
    //    exit();
    //}
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

	perlinScaleSlider = cp5.addSlider("pperlinScale").setPosition(90,450).setSize(230,30).setCaptionLabel("Perlin Scale").setRange(-0.001,.2).setColorValue(color(0)).setColorLabel(color(255));
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

    startHueSlider = cp5.addSlider("startHue").setPosition(70,130).setSize(400,30).setCaptionLabel("Base Hue").setRange(-1,360).setColorValue(color(0)).setColorLabel(color(255)).setTab("Color");
    startHueSlider.getValueLabel().setVisible(false);
    startHueBox = cp5.addTextfield("_startHue").setPosition(20,130).setSize(50,30).setCaptionLabel("").setColorValue(color(0,0,0)).setColorActive(color(255,0,0)).setTab("Color");
    boxes.add(startHueBox);
    startSatSlider = cp5.addSlider("startSat").setPosition(70,160).setSize(400,30).setCaptionLabel("Base Saturation").setRange(-1,100).setColorValue(color(0)).setColorLabel(color(255)).setTab("Color");
    startSatSlider.getValueLabel().setVisible(false);
    startSatBox = cp5.addTextfield("_startSat").setPosition(20,160).setSize(50,30).setCaptionLabel("").setColorValue(color(0,0,0)).setColorActive(color(255,0,0)).setTab("Color");
    boxes.add(startSatBox);
    startBriSlider = cp5.addSlider("startBri").setPosition(70,190).setSize(400,30).setCaptionLabel("Base Brightness").setRange(-1,100).setColorValue(color(0)).setColorLabel(color(255)).setTab("Color");
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
        for(int i = 0; i < subList.getItems().size(); i++) {
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
        for(int i = 0; i < subList.getItems().size(); i++) {
            subList.getItem(i).put("state", subsTri.get(i));
        }
    } else if (shape == 1) { //Hexagon
        subList.addItems(new String[] {"Inscribe Triangle", "3-Way Split", "4-Way Split", "6-Way Split", "Half"});
        for(int i = 0; i < subList.getItems().size(); i++) {
            subList.getItem(i).put("state", subsHex.get(i));
        }
    } else if (shape == 2 || shape == 3) { //Square
        subList.addItems(new String[] {"Quarters", "Diagonal", "Half", "Inscribe Diamond"});
        for(int i = 0; i < subList.getItems().size(); i++) {
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
        while (seed.length() < 10) {
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
		yCount = int(size * 4/3);
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
            pointData leftTop = new pointData(x * height/size/2 * s3 - (y%2==0? 0 : height/size/4 * s3), y * height/size - height/size/4 * y);
            pointData top = new pointData((x * height/size/2 * s3 - (y%2==0? 0 : height/size/4 * s3)) + height/size/4 * s3, y * height/size - height/size/4 - height/size/4 * y);
            pointData rightTop = new pointData((x * height/size/2 * s3 - (y%2==0? 0 : height/size/4 * s3)) + height/size/2 * s3, y * height/size - height/size/4 * y);
            pointData rightBottom = new pointData((x * height/size/2 * s3 - (y%2==0? 0 : height/size/4 * s3)) + height/size/2 * s3, y * height/size + height/size/2 - height/size/4 * y);
            pointData bottom = new pointData((x * height/size/2 * s3 - (y%2==0? 0 : height/size/4 * s3)) + height/size/4 * s3, y * height/size + height/size*3/4 - height/size/4 * y);
            pointData leftBottom = new pointData(x * height/size/2 * s3 - (y%2==0? 0 : height/size/4 * s3), y * height/size + height/size/2 - height/size/4 * y);
            pointData center = new pointData((x * height/size/2 * s3 - (y%2==0? 0 : height/size/4 * s3)) + height/size/4 * s3, y * height/size + height/size/4 - height/size/4 * y);
            pointData squareTL = new pointData(x*height/size,y*height/size);
            pointData squareTR = new pointData((x+1)*height/size,y*height/size);
            pointData squareBL = new pointData(x*height/size,(y+1)*height/size);
            pointData squareBR = new pointData((x+1)*height/size,(y+1)*height/size);
            pointData squareOTL = new pointData(x*height/size - (y%2==0? 0 : height/size/2),y*height/size);
            pointData squareOTR = new pointData((x+1)*height/size - (y%2==0? 0 : height/size/2),y*height/size);
            pointData squareOBL = new pointData(x*height/size - (y%2==0? 0 : height/size/2),(y+1)*height/size);
            pointData squareOBR = new pointData((x+1)*height/size - (y%2==0? 0 : height/size/2),(y+1)*height/size);

            switch(shape) {
                case 0: //Equilateral Triangle
                    shapes.add(new Shape(ShapeType.TRI, leftTop, top, center));
                    shapes.add(new Shape(ShapeType.TRI, top, rightTop, center));
                    shapes.add(new Shape(ShapeType.TRI, rightTop, rightBottom, center));
                    shapes.add(new Shape(ShapeType.TRI, rightBottom, bottom, center));
                    shapes.add(new Shape(ShapeType.TRI, bottom, leftBottom, center));
                    shapes.add(new Shape(ShapeType.TRI, leftBottom, leftTop, center));
                    break;
                case 1: //Hexagon
                    shapes.add(new Shape(ShapeType.HEX, leftTop, top, rightTop, rightBottom, bottom, leftBottom));
                    break;
                case 2: //Square
                    shapes.add(new Shape(ShapeType.SQUARE, squareTL, squareBR));
                    break;
                case 3: //Square Offset
                    shapes.add(new Shape(ShapeType.SQUARE, squareOTL, squareOBR));
                    break;
                case 4: //Right Triangle
                    if (getRandomBoolean()) {
                        shapes.add(new Shape(ShapeType.TRI, squareTL, squareTR, squareBR));
                        shapes.add(new Shape(ShapeType.TRI, squareTL, squareBL, squareBR));
                    } else {
                        shapes.add(new Shape(ShapeType.TRI, squareTR, squareBR, squareBL));
                        shapes.add(new Shape(ShapeType.TRI, squareTL, squareTR, squareBL));
                    }
                    break;
                case 5: //Right Triangle Offset
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
                case 0:{//4 Triangles
                    pointData oneTwo = midPoint(s.one, s.two);
                    pointData twoThree = midPoint(s.two, s.three);
                    pointData threeOne = midPoint(s.three, s.one);
                    shapes.add(new Shape(ShapeType.TRI, oneTwo, twoThree, threeOne, s.depth + 1));
                    shapes.add(new Shape(ShapeType.TRI, s.one, oneTwo, threeOne, s.depth + 1));
                    shapes.add(new Shape(ShapeType.TRI, s.two, oneTwo, twoThree, s.depth + 1));
                    shapes.add(new Shape(ShapeType.TRI, s.three, threeOne, twoThree, s.depth + 1));
        			if (s.depth + 1 < Integer.parseInt(subDepthBox.getText()) && triS) {
                        shapesToSub.add(new Shape(ShapeType.TRI, oneTwo, twoThree, threeOne, s.depth + 1));
                        shapesToSub.add(new Shape(ShapeType.TRI, s.one, oneTwo, threeOne, s.depth + 1));
                        shapesToSub.add(new Shape(ShapeType.TRI, s.two, oneTwo, twoThree, s.depth + 1));
        				shapesToSub.add(new Shape(ShapeType.TRI, s.three, threeOne, twoThree, s.depth + 1));
        			}
                    break;}
                case 1:{//Vertex-Midpoint
                    pointData oneTwo = midPoint(s.one, s.two);
                    pointData twoThree = midPoint(s.two, s.three);
                    pointData threeOne = midPoint(s.three, s.one);
                    switch(getRandomCase(3)) {
                        case 0:
                            shapes.add(new Shape(ShapeType.TRI, s.one, s.two, threeOne, s.depth + 1));
                            shapes.add(new Shape(ShapeType.TRI, s.three, s.two, threeOne, s.depth + 1));
                            if (s.depth + 1 < Integer.parseInt(subDepthBox.getText()) && triS) {
                                shapesToSub.add(new Shape(ShapeType.TRI, s.one, s.two, threeOne, s.depth + 1));
                				shapesToSub.add(new Shape(ShapeType.TRI, s.three, s.two, threeOne, s.depth + 1));
                			}
                            break;
                        case 1:
                            shapes.add(new Shape(ShapeType.TRI, s.two, s.three, oneTwo, s.depth + 1));
                            shapes.add(new Shape(ShapeType.TRI, s.one, s.three, oneTwo, s.depth + 1));
                            if (s.depth + 1 < Integer.parseInt(subDepthBox.getText()) && triS) {
                                shapesToSub.add(new Shape(ShapeType.TRI, s.two, s.three, oneTwo, s.depth + 1));
                                shapesToSub.add(new Shape(ShapeType.TRI, s.one, s.three, oneTwo, s.depth + 1));
                            }
                            break;
                        case 2:
                            shapes.add(new Shape(ShapeType.TRI, s.three, s.one, twoThree, s.depth + 1));
                            shapes.add(new Shape(ShapeType.TRI, s.two, s.one, twoThree, s.depth + 1));
                            if (s.depth + 1 < Integer.parseInt(subDepthBox.getText()) && triS) {
                                shapesToSub.add(new Shape(ShapeType.TRI, s.three, s.one, twoThree, s.depth + 1));
                                shapesToSub.add(new Shape(ShapeType.TRI, s.two, s.one, twoThree, s.depth + 1));
                            }
                            break;
                    }
                    break;}
                case 2:{//Center Split
                    pointData oneTwo = midPoint(s.one, s.two);
                    pointData twoThree = midPoint(s.two, s.three);
                    pointData threeOne = midPoint(s.three, s.one);
                    pointData cen = midPoint(new pointData[] {s.one, s.two, s.three});
                    shapes.add(new Shape(ShapeType.TRI, s.one, s.two, cen, s.depth + 1));
                    shapes.add(new Shape(ShapeType.TRI, s.two, s.three, cen, s.depth + 1));
                    shapes.add(new Shape(ShapeType.TRI, s.three, s.one, cen, s.depth + 1));
        			if (s.depth + 1 < Integer.parseInt(subDepthBox.getText()) && triS) {
                        shapesToSub.add(new Shape(ShapeType.TRI, s.one, s.two, cen, s.depth + 1));
                        shapesToSub.add(new Shape(ShapeType.TRI, s.two, s.three, cen, s.depth + 1));
        				shapesToSub.add(new Shape(ShapeType.TRI, s.three, s.one, cen, s.depth + 1));
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
                case 0:{//Inscribe triangle
                    // pointData oneTwo = midPoint(s.one,s.two);
                    // pointData twoThree = midPoint(s.two,s.three);
                    // pointData threeFour = midPoint(s.three,s.four);
                    // pointData fourFive = midPoint(s.four,s.five);
                    // pointData fiveSix = midPoint(s.five,s.six);
                    // pointData sixOne = midPoint(s.six,s.one);
                    switch(getRandomCase(2)) {
                        case 0:
                            shapes.add(new Shape(ShapeType.TRI, s.one, s.three, s.five, s.depth + 1));
                            shapes.add(new Shape(ShapeType.TRI, s.one, s.two, s.three, s.depth + 1));
                            shapes.add(new Shape(ShapeType.TRI, s.three, s.four, s.five, s.depth + 1));
                            shapes.add(new Shape(ShapeType.TRI, s.five, s.six, s.one, s.depth + 1));
                            if (s.depth + 1 < Integer.parseInt(subDepthBox.getText()) && triS) {
                                shapesToSub.add(new Shape(ShapeType.TRI, s.one, s.three, s.five, s.depth + 1));
                                shapesToSub.add(new Shape(ShapeType.TRI, s.one, s.two, s.three, s.depth + 1));
                                shapesToSub.add(new Shape(ShapeType.TRI, s.three, s.four, s.five, s.depth + 1));
                                shapesToSub.add(new Shape(ShapeType.TRI, s.five, s.six, s.one, s.depth + 1));
                            }
                            break;
                        case 1:
                            shapes.add(new Shape(ShapeType.TRI, s.two, s.four, s.six, s.depth + 1));
                            shapes.add(new Shape(ShapeType.TRI, s.two, s.three, s.four, s.depth + 1));
                            shapes.add(new Shape(ShapeType.TRI, s.four, s.five, s.six, s.depth + 1));
                            shapes.add(new Shape(ShapeType.TRI, s.six, s.one, s.two, s.depth + 1));
                            if (s.depth + 1 < Integer.parseInt(subDepthBox.getText()) && triS) {
                                shapesToSub.add(new Shape(ShapeType.TRI, s.two, s.four, s.six, s.depth + 1));
                                shapesToSub.add(new Shape(ShapeType.TRI, s.two, s.three, s.four, s.depth + 1));
                                shapesToSub.add(new Shape(ShapeType.TRI, s.four, s.five, s.six, s.depth + 1));
                                shapesToSub.add(new Shape(ShapeType.TRI, s.six, s.one, s.two, s.depth + 1));
                            }
                            break;
                    }
                    break;}
                case 1:{//3-Way Split
                    pointData cen = midPoint(s.one, s.four);
                    switch(getRandomCase(2)) {
                        case 0:
                            shapes.add(new Shape(ShapeType.QUAD, s.one, s.two, s.three, cen, s.depth + 1));
                            shapes.add(new Shape(ShapeType.QUAD, s.three, s.four, s.five, cen, s.depth + 1));
                            shapes.add(new Shape(ShapeType.QUAD, s.five, s.six, s.one, cen, s.depth + 1));
                            // if (s.depth + 1 < Integer.parseInt(subDepthBox.getText())) {
                            //     shapesToSub.add(new Shape(ShapeType.QUAD, s.one, s.two, s.three, cen, s.depth + 1));
                            //     shapesToSub.add(new Shape(ShapeType.QUAD, s.three, s.four, s.five, cen, s.depth + 1));
                            //     shapesToSub.add(new Shape(ShapeType.QUAD, s.five, s.six, s.one, cen, s.depth + 1));
                            // }
                            break;
                        case 1:
                            shapes.add(new Shape(ShapeType.QUAD, s.two, s.three, s.four, cen, s.depth + 1));
                            shapes.add(new Shape(ShapeType.QUAD, s.four, s.five, s.six, cen, s.depth + 1));
                            shapes.add(new Shape(ShapeType.QUAD, s.six, s.one, s.two, cen, s.depth + 1));
                            // if (s.depth + 1 < Integer.parseInt(subDepthBox.getText())) {
                            //     shapesToSub.add(new Shape(ShapeType.QUAD, s.two, s.three, s.four, cen, s.depth + 1));
                            //     shapesToSub.add(new Shape(ShapeType.QUAD, s.four, s.five, s.six, cen, s.depth + 1));
                            //     shapesToSub.add(new Shape(ShapeType.QUAD, s.six, s.one, s.two, cen, s.depth + 1));
                            // }
                            break;
                    }
                    break;}
                case 2:{//4-Way Split
                    pointData cen = midPoint(s.one, s.four);
                    switch(getRandomCase(3)) {
                        case 0:
                            shapes.add(new Shape(ShapeType.QUAD, s.one, s.two, s.three, cen, s.depth + 1));
                            shapes.add(new Shape(ShapeType.QUAD, s.four, s.five, s.six, cen, s.depth + 1));
                            shapes.add(new Shape(ShapeType.TRI, s.three, s.four, cen, s.depth + 1));
                            shapes.add(new Shape(ShapeType.TRI, s.six, s.one, cen, s.depth + 1));
                            if (s.depth + 1 < Integer.parseInt(subDepthBox.getText()) && triS) {
                                // shapesToSub.add(new Shape(ShapeType.QUAD, s.one, s.two, s.three, cen, s.depth + 1));
                                // shapesToSub.add(new Shape(ShapeType.QUAD, s.four, s.five, s.six, cen, s.depth + 1));
                                shapesToSub.add(new Shape(ShapeType.TRI, s.three, s.four, cen, s.depth + 1));
                                shapesToSub.add(new Shape(ShapeType.TRI, s.six, s.one, cen, s.depth + 1));
                            }
                            break;
                        case 1:
                            shapes.add(new Shape(ShapeType.QUAD, s.two, s.three, s.four, cen, s.depth + 1));
                            shapes.add(new Shape(ShapeType.QUAD, s.five, s.six, s.one, cen, s.depth + 1));
                            shapes.add(new Shape(ShapeType.TRI, s.four, s.five, cen, s.depth + 1));
                            shapes.add(new Shape(ShapeType.TRI, s.one, s.two, cen, s.depth + 1));
                            if (s.depth + 1 < Integer.parseInt(subDepthBox.getText()) && triS) {
                                // shapesToSub.add(new Shape(ShapeType.QUAD, s.two, s.three, s.four, cen, s.depth + 1));
                                // shapesToSub.add(new Shape(ShapeType.QUAD, s.five, s.six, s.one, cen, s.depth + 1));
                                shapesToSub.add(new Shape(ShapeType.TRI, s.four, s.five, cen, s.depth + 1));
                                shapesToSub.add(new Shape(ShapeType.TRI, s.one, s.two, cen, s.depth + 1));
                            }
                            break;
                        case 2:
                            shapes.add(new Shape(ShapeType.QUAD, s.three, s.four, s.five, cen, s.depth + 1));
                            shapes.add(new Shape(ShapeType.QUAD, s.six, s.one, s.two, cen, s.depth + 1));
                            shapes.add(new Shape(ShapeType.TRI, s.five, s.six, cen, s.depth + 1));
                            shapes.add(new Shape(ShapeType.TRI, s.two, s.three, cen, s.depth + 1));
                            if (s.depth + 1 < Integer.parseInt(subDepthBox.getText()) && triS) {
                                // shapesToSub.add(new Shape(ShapeType.QUAD, s.three, s.four, s.five, cen, s.depth + 1));
                                // shapesToSub.add(new Shape(ShapeType.QUAD, s.six, s.one, s.two, cen, s.depth + 1));
                                shapesToSub.add(new Shape(ShapeType.TRI, s.five, s.six, cen, s.depth + 1));
                                shapesToSub.add(new Shape(ShapeType.TRI, s.two, s.three, cen, s.depth + 1));
                            }
                            break;
                    }
                    break;}
                case 3:{//6-Way Split
                    pointData cen = midPoint(s.one, s.four);
                    shapes.add(new Shape(ShapeType.TRI, s.one, s.two, cen, s.depth + 1));
                    shapes.add(new Shape(ShapeType.TRI, s.two, s.three, cen, s.depth + 1));
                    shapes.add(new Shape(ShapeType.TRI, s.three, s.four, cen, s.depth + 1));
                    shapes.add(new Shape(ShapeType.TRI, s.four, s.five, cen, s.depth + 1));
                    shapes.add(new Shape(ShapeType.TRI, s.five, s.six, cen, s.depth + 1));
                    shapes.add(new Shape(ShapeType.TRI, s.six, s.one, cen, s.depth + 1));
                    if (s.depth + 1 < Integer.parseInt(subDepthBox.getText()) && triS) {
                        shapesToSub.add(new Shape(ShapeType.TRI, s.one, s.two, cen, s.depth + 1));
                        shapesToSub.add(new Shape(ShapeType.TRI, s.two, s.three, cen, s.depth + 1));
                        shapesToSub.add(new Shape(ShapeType.TRI, s.three, s.four, cen, s.depth + 1));
                        shapesToSub.add(new Shape(ShapeType.TRI, s.four, s.five, cen, s.depth + 1));
                        shapesToSub.add(new Shape(ShapeType.TRI, s.five, s.six, cen, s.depth + 1));
                        shapesToSub.add(new Shape(ShapeType.TRI, s.six, s.one, cen, s.depth + 1));
                    }
                    break;}
                case 4:{//Half
                    switch(getRandomCase(3)) {
                        case 0:
                            shapes.add(new Shape(ShapeType.QUAD, s.one, s.two, s.three, s.four, s.depth + 1));
                            shapes.add(new Shape(ShapeType.QUAD, s.four, s.five, s.six, s.one, s.depth + 1));
                            // if (s.depth + 1 < Integer.parseInt(subDepthBox.getText())) {
                            //     shapesToSub.add(new Shape(ShapeType.QUAD, s.one, s.two, s.three, s.four, s.depth + 1));
                            //     shapesToSub.add(new Shape(ShapeType.QUAD, s.four, s.five, s.six, s.one, s.depth + 1));
                            // }
                            break;
                        case 1:
                            shapes.add(new Shape(ShapeType.QUAD, s.two, s.three, s.four, s.five, s.depth + 1));
                            shapes.add(new Shape(ShapeType.QUAD, s.five, s.six, s.one, s.two, s.depth + 1));
                            // if (s.depth + 1 < Integer.parseInt(subDepthBox.getText())) {
                            //     shapesToSub.add(new Shape(ShapeType.QUAD, s.two, s.three, s.four, s.five, s.depth + 1));
                            //     shapesToSub.add(new Shape(ShapeType.QUAD, s.five, s.six, s.one, s.two, s.depth + 1));
                            // }
                            break;
                        case 2:
                            shapes.add(new Shape(ShapeType.QUAD, s.three, s.four, s.five, s.six, s.depth + 1));
                            shapes.add(new Shape(ShapeType.QUAD, s.six, s.one, s.two, s.three, s.depth + 1));
                            // if (s.depth + 1 < Integer.parseInt(subDepthBox.getText())) {
                            //     shapesToSub.add(new Shape(ShapeType.QUAD, s.three, s.four, s.five, s.six, s.depth + 1));
                            //     shapesToSub.add(new Shape(ShapeType.QUAD, s.six, s.one, s.two, s.three, s.depth + 1));
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
                case 0:{//Quarters
                    pointData topMid = midPoint(s.one, new pointData(s.two.x, s.one.y));
                    pointData leftMid = midPoint(s.one, new pointData(s.one.x, s.two.y));
                    pointData bottomMid = midPoint(s.two, new pointData(s.one.x, s.two.y));
                    pointData rightMid = midPoint(s.two, new pointData(s.two.x, s.one.y));
                    pointData mid = midPoint(s.one, s.two);
                    shapes.add(new Shape(ShapeType.SQUARE, s.one, mid, s.depth + 1));
                    shapes.add(new Shape(ShapeType.SQUARE, leftMid, bottomMid, s.depth + 1));
                    shapes.add(new Shape(ShapeType.SQUARE, mid, s.two, s.depth + 1));
                    shapes.add(new Shape(ShapeType.SQUARE, topMid, rightMid, s.depth + 1));
        			if (s.depth + 1 < Integer.parseInt(subDepthBox.getText()) && squS) {
                        shapesToSub.add(new Shape(ShapeType.SQUARE, s.one, mid, s.depth + 1));
                        shapesToSub.add(new Shape(ShapeType.SQUARE, leftMid, bottomMid, s.depth + 1));
                        shapesToSub.add(new Shape(ShapeType.SQUARE, mid, s.two, s.depth + 1));
        				shapesToSub.add(new Shape(ShapeType.SQUARE, topMid, rightMid, s.depth + 1));
        			}
                    break;}
                case 1:{//Diagonal
                    pointData topRight = new pointData(s.two.x, s.one.y);
                    pointData botLeft = new pointData(s.one.x, s.two.y);
                    pointData mid = midPoint(s.one, s.two);
                    shapes.add(new Shape(ShapeType.TRI, s.one, topRight, mid, s.depth + 1));
                    shapes.add(new Shape(ShapeType.TRI, topRight, s.two, mid, s.depth + 1));
                    shapes.add(new Shape(ShapeType.TRI, s.two, botLeft, mid, s.depth + 1));
                    shapes.add(new Shape(ShapeType.TRI, botLeft, s.one, mid, s.depth + 1));
        			if (s.depth + 1 < Integer.parseInt(subDepthBox.getText()) && triS) {
                        shapesToSub.add(new Shape(ShapeType.TRI, s.one, topRight, mid, s.depth + 1));
                        shapesToSub.add(new Shape(ShapeType.TRI, topRight, s.two, mid, s.depth + 1));
                        shapesToSub.add(new Shape(ShapeType.TRI, s.two, botLeft, mid, s.depth + 1));
        				shapesToSub.add(new Shape(ShapeType.TRI, botLeft, s.one, mid, s.depth + 1));
        			}
                    break;}
                case 2:{//Half split
                    pointData topMid = midPoint(s.one, new pointData(s.two.x, s.one.y));
                    pointData leftMid = midPoint(s.one, new pointData(s.one.x, s.two.y));
                    pointData bottomMid = midPoint(s.two, new pointData(s.one.x, s.two.y));
                    pointData rightMid = midPoint(s.two, new pointData(s.two.x, s.one.y));
                    switch(getRandomCase(2)) {
                        case 0:
                            shapes.add(new Shape(ShapeType.SQUARE, s.one, bottomMid, s.depth + 1));
                            shapes.add(new Shape(ShapeType.SQUARE, topMid, s.two, s.depth + 1));
                            if (s.depth + 1 < Integer.parseInt(subDepthBox.getText()) && squS) {
                                shapesToSub.add(new Shape(ShapeType.SQUARE, s.one, bottomMid, s.depth + 1));
                                shapesToSub.add(new Shape(ShapeType.SQUARE, topMid, s.two, s.depth + 1));
                            }
                            break;
                        case 1:
                            shapes.add(new Shape(ShapeType.SQUARE, s.one, rightMid, s.depth + 1));
                            shapes.add(new Shape(ShapeType.SQUARE, leftMid, s.two, s.depth + 1));
                            if (s.depth + 1 < Integer.parseInt(subDepthBox.getText()) && squS) {
                                shapesToSub.add(new Shape(ShapeType.SQUARE, s.one, rightMid, s.depth + 1));
                                shapesToSub.add(new Shape(ShapeType.SQUARE, leftMid, s.two, s.depth + 1));
                            }
                            break;
                    }
                    break;}
                case 3:{//Inscribe diamond
                    pointData topMid = midPoint(s.one, new pointData(s.two.x, s.one.y));
                    pointData leftMid = midPoint(s.one, new pointData(s.one.x, s.two.y));
                    pointData bottomMid = midPoint(s.two, new pointData(s.one.x, s.two.y));
                    pointData rightMid = midPoint(s.two, new pointData(s.two.x, s.one.y));
                    pointData topRight = new pointData(s.two.x, s.one.y);
                    pointData botLeft = new pointData(s.one.x, s.two.y);
                    shapes.add(new Shape(ShapeType.TRI, s.one, topMid, leftMid, s.depth + 1));
                    shapes.add(new Shape(ShapeType.TRI, topMid, topRight, rightMid, s.depth + 1));
                    shapes.add(new Shape(ShapeType.TRI, rightMid, s.two, bottomMid, s.depth + 1));
                    shapes.add(new Shape(ShapeType.TRI, bottomMid, botLeft, leftMid, s.depth + 1));
                    shapes.add(new Shape(ShapeType.QUAD, topMid, rightMid, bottomMid, leftMid, s.depth + 1));
        			if (s.depth + 1 < Integer.parseInt(subDepthBox.getText()) && triS) {
                        shapesToSub.add(new Shape(ShapeType.TRI, s.one, topMid, leftMid, s.depth + 1));
                        shapesToSub.add(new Shape(ShapeType.TRI, topMid, topRight, rightMid, s.depth + 1));
                        shapesToSub.add(new Shape(ShapeType.TRI, rightMid, s.two, bottomMid, s.depth + 1));
                        shapesToSub.add(new Shape(ShapeType.TRI, bottomMid, botLeft, leftMid, s.depth + 1));
        				// shapesToSub.add(new Shape(ShapeType.QUAD, topMid, rightMid, bottomMid, leftMid, s.depth + 1));
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
	colors.add(color(startHue >= 0? startHue : random(0,360), startSat >= 0? startSat : random(0, 100), startBri >= 0? startBri : random(0,100)));

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

    switch (mode) {
        case 0: //Intermediate
            for (int i = 1; i < count; i++) {
                hueCurrent = iHue + i * spacingH;
                while (hueCurrent > 360) {
                    hueCurrent -= 360;
                }
                satCurrent = iSat - i * satSpacing;
                while (satCurrent < 0) {
                    satCurrent += 100;
                }
                briCurrent = iBri - i * briSpacing;
                while (briCurrent < 0) {
                    briCurrent += 100;
                }
				colors.add(color(hueCurrent, satCurrent, briCurrent));
            }
            break;
        case 1: //Analogous
            for (int i = 1; i < count; i++) {
                hueCurrent = iHue + i * round(hueSpacing);
                while (hueCurrent > 360) {
                    hueCurrent -= 360;
                }
                satCurrent = iSat - i * satSpacing;
                while (satCurrent < 0) {
                    satCurrent += 100;
                }
                briCurrent = iBri - i * briSpacing;
                while (briCurrent < 0) {
                    briCurrent += 100;
                }
				colors.add(color(hueCurrent, satCurrent, briCurrent));
            }
            break;
        case 2: //Shades
            for (int i = 1; i < count; i++) {
                briCurrent = iBri - i * briSpacing;
                while (briCurrent < 0) {
                    briCurrent += 100;
                }
                satCurrent = iSat - i * satSpacing;
                while (satCurrent < 0) {
                    satCurrent += 100;
                }
				colors.add(color(hueCurrent, satCurrent, briCurrent));
            }
            break;
        case 3: //Monochromatic
            for (int i = 1; i < count; i++) {
                satCurrent = iSat - i * satSpacing;
                while (satCurrent < 0) {
                    satCurrent += 100;
                }
                briCurrent = iBri - i * briSpacing;
                while (briCurrent < 0) {
                    briCurrent += 100;
                }
                colors.add(color(hueCurrent, satCurrent, briCurrent));
            }
            break;
        case 4: //Complimentary
            for (int i = 1; i < count; i++) {
                hueCurrent = iHue + i * 180;
                while (hueCurrent > 360) {
                    hueCurrent -= 360;
                }
                satCurrent = iSat - i * satSpacing;
                while (satCurrent < 0) {
                    satCurrent += 100;
                }
                briCurrent = iBri - i * briSpacing;
                while (briCurrent < 0) {
                    briCurrent += 100;
                }
				colors.add(color(hueCurrent, satCurrent, briCurrent));
            }
            break;
        case 5: //Left Complimentary
            for (int i = 1; i < count; i++) {
                hueCurrent = iHue + (i%2 == 1? 150 : 0);
                while (hueCurrent > 360) {
                    hueCurrent -= 360;
                }
                satCurrent = iSat - i * satSpacing;
                while (satCurrent < 0) {
                    satCurrent += 100;
                }
                briCurrent = iBri - i * briSpacing;
                while (briCurrent < 0) {
                    briCurrent += 100;
                }
				colors.add(color(hueCurrent, satCurrent, briCurrent));
            }
            break;
        case 6: //Right Complimentary
            for (int i = 1; i < count; i++) {
                hueCurrent = iHue + (i%2 == 1? 210 : 0);
                while (hueCurrent > 360) {
                    hueCurrent -= 360;
                }
                satCurrent = iSat - i * satSpacing;
                while (satCurrent < 0) {
                    satCurrent += 100;
                }
                briCurrent = iBri - i * briSpacing;
                while (briCurrent < 0) {
                    briCurrent += 100;
                }
				colors.add(color(hueCurrent, satCurrent, briCurrent));
            }
            break;
        case 7: //Split Complimentary
            for (int i = 1; i < count; i++) {
                hueCurrent = iHue + (i%3 == 1? 150 : i%3 == 2? 210 : 0);
                while (hueCurrent > 360) {
                    hueCurrent -= 360;
                }
                satCurrent = iSat - i * satSpacing;
                while (satCurrent < 0) {
                    satCurrent += 100;
                }
                briCurrent = iBri - i * briSpacing;
                while (briCurrent < 0) {
                    briCurrent += 100;
                }
				colors.add(color(hueCurrent, satCurrent, briCurrent));
            }
            break;
        case 8: //Triad
            for (int i = 1; i < count; i++) {
                hueCurrent = iHue + i * 120;
                while (hueCurrent > 360) {
                    hueCurrent -= 360;
                }
                satCurrent = iSat - i * satSpacing;
                while (satCurrent < 0) {
                    satCurrent += 100;
                }
                briCurrent = iBri - i * briSpacing;
                while (briCurrent < 0) {
                    briCurrent += 100;
                }
				colors.add(color(hueCurrent, satCurrent, briCurrent));
            }
            break;
        case 9: //Tetrad
            for (int i = 1; i < count; i++) {
                hueCurrent = iHue + i * 90;
                while (hueCurrent > 360) {
                    hueCurrent -= 360;
                }
                satCurrent = iSat - i * satSpacing;
                while (satCurrent < 0) {
                    satCurrent += 100;
                }
                briCurrent = iBri - i * briSpacing;
                while (briCurrent < 0) {
                    briCurrent += 100;
                }
				colors.add(color(hueCurrent, satCurrent, briCurrent));
            }
            break;
        case 10: //Pentagram
            for (int i = 1; i < count; i++) {
                hueCurrent = iHue + i * 72;
                while (hueCurrent > 360) {
                    hueCurrent -= 360;
                }
                satCurrent = iSat - i * satSpacing;
                while (satCurrent < 0) {
                    satCurrent += 100;
                }
                briCurrent = iBri - i * briSpacing;
                while (briCurrent < 0) {
                    briCurrent += 100;
                }
				colors.add(color(hueCurrent, satCurrent, briCurrent));
            }
            break;
        case 11: //Compound Left
            for (int i = 1; i < count; i++) {
                hueCurrent = iHue + (i%4 == 1? 150 : i%4 == 2? 120 : i%4 == 3? 60 : 0);
                while (hueCurrent > 360) {
                    hueCurrent -= 360;
                }
                satCurrent = iSat - i * satSpacing;
                while (satCurrent < 0) {
                    satCurrent += 100;
                }
                briCurrent = iBri - i * briSpacing;
                while (briCurrent < 0) {
                    briCurrent += 100;
                }
				colors.add(color(hueCurrent, satCurrent, briCurrent));
            }
            break;
        case 12: //Compound Right
            for (int i = 1; i < count; i++) {
                hueCurrent = iHue + (i%4 == 1? 210 : i%4 == 2? 240 : i%4 == 3? 300 : 0);
                while (hueCurrent > 360) {
                    hueCurrent -= 360;
                }
                satCurrent = iSat - i * satSpacing;
                while (satCurrent < 0) {
                    satCurrent += 100;
                }
                briCurrent = iBri - i * briSpacing;
                while (briCurrent < 0) {
                    briCurrent += 100;
                }
				colors.add(color(hueCurrent, satCurrent, briCurrent));
            }
            break;
    }
}

color rColor(Shape shape) {
	color c = colors.get(int(random(0,colors.size())));
	switch (noiseMode) {
		case 1: //Color Mode
			return colors.get(int(noise(shape.midPoint.x * perlinScale, shape.midPoint.y * perlinScale) * colors.size()));
		case 2: //Brightnes Tint Mode
			return color(hue(c), saturation(c), noise(shape.midPoint.x * perlinScale, shape.midPoint.y * perlinScale) * 100);
		case 3: //Saturation Tint Mode
			return color(hue(c), noise(shape.midPoint.x * perlinScale, shape.midPoint.y * perlinScale) * 100, brightness(c));
		default:
			return c;
	}
}

color rColor(pointData point) {
	color c = colors.get(int(random(0,colors.size())));
	switch (noiseMode) {
		case 1: //Color Mode
			return colors.get(int(noise(point.x * perlinScale, point.y * perlinScale) * colors.size()));
		case 2: //Brightnes Tint Mode
			return color(hue(c), saturation(c), noise(point.x * perlinScale, point.y * perlinScale) * 100);
		case 3: //Saturation Tint Mode
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
            boxesVis.get(boxesVis.size()-1).setFocus(false);
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
	while (perlinSeed.length() < 10) {
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
           String t = (box.getText().substring(box.getText().length()-1).toLowerCase().compareTo("c") != 0 && box.getText().substring(box.getText().length()-1).toLowerCase().compareTo("") != 0)? box.getText() : box.getText().substring(0, box.getText().length() - 1);
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
			String t = (box.getText().substring(box.getText().length()-1).toLowerCase().compareTo("c") != 0)? box.getText() : box.getText().substring(0, box.getText().length() - 1);
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
    File dir = new File (docsPath + "ShapePlane/presets");
	presetList.clear();
	if (!dir.exists()) {
		dir.mkdir();
	} else if (dir.listFiles() != null) {
		File[] files = dir.listFiles();
		for(int i = 0; i < files.length; i++) {
			presetList.addItems(new String[] {stripExtension(files[i].getName())});
		}
	}
}

float withinLoopBounds(float initial, float max) {
    float i = initial;
    while (i > max) {
        i -= max;
    }
    return i;
}

String stripExtension (String fileString) {
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
    		Button but = cp5.addButton("b" + i).setPosition(i * wid, height-90).setSize(int(wid),90).setCaptionLabel("").setColorActive(colors.get(i)).setColorBackground(colors.get(i)).setColorForeground(colors.get(i)).setTab("Color");
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
    } catch (UnsupportedFlavorException e) {
        println(e);
    } finally {
        return str;
    }
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
    subsTriTemp = subsTriTemp.substring(0, subsTriTemp.length()-1);
    String subsHexTemp = "";
    for (boolean b : subsHex) {
        subsHexTemp += (b + ",");
    }
    subsHexTemp = subsHexTemp.substring(0, subsHexTemp.length()-1);
    String subsSquareTemp = "";
    for (boolean b : subsSquare) {
        subsSquareTemp += (b + ",");
    }
    subsSquareTemp = subsSquareTemp.substring(0, subsSquareTemp.length()-1);
    saveStrings(docsPath + "ShapePlane/presets/" + (st.compareTo("") == 0? "newPreset" : st) + ".txt", new String[] {"" + (int)size + "\n" + (int)colorCount + "\n" + (int)hueSpacing + "\n" + (int)mode + "\n" +
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
    subsTriTemp = subsTriTemp.length() == 0? "" : subsTriTemp.substring(0, subsTriTemp.length()-1);
    String subsHexTemp = "";
    for (boolean b : subsHex) {
        subsHexTemp += (b + ",");
    }
    subsHexTemp = subsHexTemp.length() == 0? "" : subsHexTemp.substring(0, subsHexTemp.length()-1);
    String subsSquareTemp = "";
    for (boolean b : subsSquare) {
        subsSquareTemp += (b + ",");
    }
    subsSquareTemp = subsSquareTemp.length() == 0? "" : subsSquareTemp.substring(0, subsSquareTemp.length()-1);
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
    File file = new File (docsPath + "ShapePlane/presets/" + presetList.getItem(preset).entrySet().toArray()[3].toString().replace("text=", "") + ".txt");
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
	File dir = new File (docsPath + "ShapePlane/images");

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
    return (float)(Math.random() * range + min);
}

void hexagon(pointData a, pointData b, pointData c, pointData d, pointData e, pointData f) {
	beginShape();
	vertex(a.x, a.y);
	vertex(b.x, b.y);
	vertex(c.x, c.y);
	vertex(d.x, d.y);
	vertex(e.x, e.y);
	vertex(f.x, f.y);
	endShape(CLOSE);
}

void tri(pointData a, pointData b, pointData c) {
	beginShape();
	vertex(a.x, a.y);
	vertex(b.x, b.y);
	vertex(c.x, c.y);
	endShape(CLOSE);
}

void rectangle(pointData a, pointData b) {
	beginShape();
	vertex(a.x, a.y);
	vertex(b.x, a.y);
	vertex(b.x, b.y);
	vertex(a.x, b.y);
	endShape(CLOSE);
}

void quadra(pointData a, pointData b, pointData c, pointData d) {
	beginShape();
	vertex(a.x, a.y);
	vertex(b.x, b.y);
	vertex(c.x, c.y);
	vertex(d.x, d.y);
	endShape(CLOSE);
}

void drawPoly(Shape s) {
    beginShape();
    if (s.type == ShapeType.SQUARE) {
        vertex(s.one.x,s.one.y);
        vertex(s.two.x,s.one.y);
        vertex(s.two.x,s.two.y);
        vertex(s.one.x,s.two.y);
    } else {
        if (s.one != null) {
            vertex(s.one.x,s.one.y);
        }
        if (s.two != null) {
            vertex(s.two.x,s.two.y);
        }
        if (s.three != null) {
            vertex(s.three.x,s.three.y);
        }
        if (s.four != null) {
            vertex(s.four.x,s.four.y);
        }
        if (s.five != null) {
            vertex(s.five.x,s.five.y);
        }
        if (s.six != null) {
            vertex(s.six.x,s.six.y);
        }
    }
    endShape(CLOSE);
}

pointData midPoint(pointData a, pointData b) {
    return new pointData((a.x + b.x)/2, (a.y + b.y)/2);
}

pointData midPoint(pointData[] points) {
    float midX, midY;
    midX = midY = 0;
    for(pointData p : points) {
        midX += p.x;
        midY += p.y;
    }
    return new pointData(midX/points.length, midY/points.length);
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
    public pointData one, two, three, four, five, six, midPoint;
	public int depth;

    public Shape(Shape s) {
        type = s.type;
        one = s.one;
        two = s.two;
        three = s.three;
        four = s.four;
        five = s.five;
        six = s.six;
        midPoint = s.midPoint;
        depth = s.depth;
    }

    public Shape(ShapeType t, pointData a, pointData b, int de) {
        one = two = three = four = five = six = midPoint = null;
        type = t;
        one = a;
        two = b;
        midPoint = midPoint(a,b);
		depth = de;
    }

	public Shape(ShapeType t, pointData a, pointData b) {
        one = two = three = four = five = six = midPoint = null;
        type = t;
        one = a;
        two = b;
        midPoint = midPoint(a,b);
		depth = 0;
    }

    public Shape(ShapeType t, pointData a, pointData b, pointData c, int de) {
        one = two = three = four = five = six = midPoint = null;
        type = t;
        one = a;
        two = b;
        three = c;
        midPoint = midPoint(new pointData[] {a,b,c});
		depth = de;
    }

	public Shape(ShapeType t, pointData a, pointData b, pointData c) {
        one = two = three = four = five = six = midPoint = null;
        type = t;
        one = a;
        two = b;
        three = c;
        midPoint = midPoint(new pointData[] {a,b,c});
		depth = 0;
    }

	public Shape(ShapeType t, pointData a, pointData b, pointData c, pointData d, int de) {
        one = two = three = four = five = six = midPoint = null;
        type = t;
        one = a;
        two = b;
        three = c;
		four = d;
        midPoint = midPoint(new pointData[] {a,b,c,d});
		depth = de;
    }

	public Shape(ShapeType t, pointData a, pointData b, pointData c, pointData d) {
        one = two = three = four = five = six = midPoint = null;
        type = t;
        one = a;
        two = b;
        three = c;
		four = d;
        midPoint = midPoint(new pointData[] {a,b,c,d});
		depth = 0;
    }

    public Shape(ShapeType t, pointData a, pointData b, pointData c, pointData d, pointData e, pointData f, int de) {
        one = two = three = four = five = six = midPoint = null;
        type = t;
        one = a;
        two = b;
        three = c;
        four = d;
        five = e;
        six = f;
        midPoint = midPoint(a,d);
		depth = de;
    }

	public Shape(ShapeType t, pointData a, pointData b, pointData c, pointData d, pointData e, pointData f) {
        one = two = three = four = five = six = midPoint = null;
        type = t;
        one = a;
        two = b;
        three = c;
        four = d;
        five = e;
        six = f;
        midPoint = midPoint(a,d);
		depth = 0;
    }
}

//LICENSE CHECKUP

boolean licenseCheckup() {
	try {
		//Download relevant license info
        File a = new File(licensePath);
    	if (!a.exists()) {
    		return false;
    	}
		LicenseDataReference ldr = fetchLDfromLicense(loadStrings(a.getAbsolutePath())[0]);
		if (ldr == null) { //Check that local license is valid
			return false;
		}
		LicenseData ld = getLicenseDataList(getLicenseInfo(ldr.ver)).get(ldr.index);
		clearLicenseInfo();
		ArrayList<LicenseDataReference> exKeysLDR = new ArrayList<LicenseDataReference>();
		ArrayList<LicenseData> exKeys = new ArrayList<LicenseData>();
		for(String exKey : ld.exKeys) {
			LicenseDataReference ldrKey = fetchLDfromLicense(exKey);
			exKeysLDR.add(ldrKey);
			exKeys.add(getLicenseDataList(getLicenseInfo(ldrKey.ver)).get(ldrKey.index));
		}
		clearLicenseInfo();
	    //Check that this computer is registered in sys list
		if (!ld.sys.contains(getSysIndentifier())) {
			return false;
		}
	    //Check that license is in date
        boolean finalReturn = false;
		if (licenseInDate(ldr.ver, ld.date) && versionPerms(ldr.ver, "ss")) {
            finalReturn = true;
		}
		for(int i = 0; i < exKeysLDR.size(); i++) { //Check that piggybacking licenses are in date
			if (licenseInDate(exKeysLDR.get(i).ver, exKeys.get(i).date) && versionPerms(exKeysLDR.get(i).ver, "ss")) {
                finalReturn = true;
			}
		}
        if (ldr.ver.compareTo("tri") == 0) {
            trial = true;
        }
        return finalReturn;
	} catch (DbxException e) {
		println("DbxException" + e);
		return false;
	} catch (IOException e) {
		println("IOException" + e);
		return false;
	} finally {
    }
}

void clearLicenseInfo() {
    File temp = new File(dataPath("temp/"));
    deleteFolder(temp);
}

void deleteFolder(File f) {
    File[] files = f.listFiles();
    if (files != null) {
        for (File fi : files) {
            if (fi.isDirectory()) {
                deleteFolder(fi);
            } else {
                fi.delete();
            }
        }
    }
    f.delete();
}

String getDate() {
    BufferedReader in;
    Socket conn;
    String date = "net"; //default value "net" -> "network issues"
    for (String ats : atomicTimeServers) {
        try {
            conn = new Socket(ats, atomicTimePort);
            in = new BufferedReader(new InputStreamReader(conn.getInputStream()));
            String atomicTime;
            while (true) {
                if ( (atomicTime = in.readLine()).indexOf("*") > -1) {
                    break;
                }
            }
            String[] dateParts = atomicTime.split(" ")[1].split("-");
            date = dateParts[1] + "/" + dateParts[2] + "/" + dateParts[0];
        } catch (UnknownHostException e) {
    		println(e);
        } catch (IOException e) {
            println(e);
        } finally {
            break;
        }
    }
    return date;
}

boolean versionPerms(String ver, String app) {
    boolean hasPerms = false;
    if (ver.compareTo("tri") == 0 || ver.compareTo("per") == 0 || ver.compareTo("edu") == 0 || ver.compareTo("pro") == 0) {
        hasPerms = true;
    } else if (ver.compareTo("ss") == 0 && app.compareTo("ss") == 0) {
        hasPerms = true;
    } else if (ver.compareTo("sp") == 0 && app.compareTo("sp") == 0) {
        hasPerms = true;
    } else if (ver.compareTo("aw") == 0 && app.compareTo("aw") == 0) {
        hasPerms = true;
    } else if (ver.compareTo("gb") == 0 && app.compareTo("gb") == 0) {
        hasPerms = true;
    }
    return hasPerms;
}

String getSysIndentifier() {
	String sys = "";
	if (os.substring(0,3).compareTo("mac") == 0) { //Mac
        ProcessBuilder ser = new ProcessBuilder("ioreg", "-l");
        try {
            BufferedReader reader = new BufferedReader(new InputStreamReader(ser.start().getInputStream()));
            String line = null;
            while ( (line = reader.readLine()) != null) {
                if (line.indexOf("IOPlatformSerialNumber") != -1) {
                    sys = line.split("=")[1].replace(" ","").replace("\"","");
					return sys;
                }
            }
        } catch (IOException e) {
            println(e);
    		return "";
        }
        // println(output);
    } else { //Windows
        ProcessBuilder ser = new ProcessBuilder("wmic", "diskdrive", "get", "serialnumber");
        try {
            BufferedReader reader = new BufferedReader(new InputStreamReader(ser.start().getInputStream()));
            String line = null;
            String complete = null;
            while ( (line = reader.readLine()) != null) {
                complete += line.replace(" ", "") + ":";
            }
            sys = complete.split("::")[1];
			return sys;
        } catch (IOException e) {
            println(e);
    		return "";
        }
        // println(output);
    }
    return sys;
}

boolean licenseInDate(String ver, String dateReg) {
    boolean inDate = false;
    String dateCur;
    if (ver.compareTo("tri") != 0) {
        inDate = true;
    } else if ((dateCur = getDate()).compareTo("net") != 0) {
        int daysFromReg = 0;
        float daysFloat = 0;
        daysFloat += 365 * (int(dateCur.split("/")[2]) - int(dateReg.split("/")[2]));
        daysFloat += (365/12) * (int(dateCur.split("/")[0]) - int(dateReg.split("/")[0]));
        daysFloat += (int(dateCur.split("/")[1]) - int(dateReg.split("/")[1]));
        daysFromReg = int(daysFloat);
        inDate = daysFromReg <= 10; //Returns true as long as trial is less than 11 days old.
    }
	return inDate;
}

ArrayList<LicenseData> getLicenseDataList(String[] txt) throws DbxException, IOException{
    ArrayList<LicenseData> data = new ArrayList<LicenseData>();
    for (String s : txt) {
        data.add(new LicenseData(s));
    }
    return data;
}

String[] getLicenseInfo(String ver) throws DbxException, IOException{ //TRI, PER, EDU, PRO
	File d = new File(dataPath("temp"));
	if (!d.exists()) {
		d.mkdir();
	}
	File a = new File(d.getPath() + "/" + ver.toLowerCase() + ".txt");
	if (!a.exists()) {
		a.createNewFile();
	}
	OutputStream out = new FileOutputStream(a);
	FileMetadata metadata = client2.files().downloadBuilder("/" + ver.toLowerCase() + ".txt").download(out);
	out.close();
	return loadStrings("data/temp/" + ver.toLowerCase() + ".txt");
}

LicenseDataReference fetchLDfromLicense(String license) throws DbxException, IOException{
    String ver = "";
    if (license.length() != 20) {
        return null;
    }
    if (license.substring(0,2).compareTo("SS") == 0 || license.substring(0,2).compareTo("SP") == 0 || license.substring(0,2).compareTo("AW") == 0 || license.substring(0,2).compareTo("GB") == 0) {
        ver = license.substring(0,2).toLowerCase();
    } else {
        switch(license.substring(0,2)) {
            case "TR":
                ver = "tri";
                break;
            case "PE":
                ver = "per";
                break;
            case "ED":
                ver = "edu";
                break;
            case "PR":
                ver = "pro";
                break;
        }
        if (ver == "") {
            return null;
        }
    }
    ArrayList<LicenseData> ld = getLicenseDataList(getLicenseInfo(ver));
    clearLicenseInfo();
    for(int i = 0; i < ld.size(); i++) {
        if (ld.get(i).lkey.compareTo(license) == 0) {
            return new LicenseDataReference(ver, i);
        }
    }
    return null;
}

String getOS() {
    return System.getProperty("os.name").toLowerCase().substring(0,3);
}

public class LicenseData {
    public String lkey, email, pass, date;
	public ArrayList<String> sys, exKeys;

    public LicenseData(String line) {
        String[] parsed = line.split("]");
        for(String s : parsed) {
            if (s.startsWith("[key:")) {
                lkey = s.replace("[key:","");
            } else if (s.startsWith("[email:")) {
                email = s.replace("[email:","");
            } else if (s.startsWith("[pass:")) {
                pass = s.replace("[pass:","");
            } else if (s.startsWith("[dateReg:")) {
                date = s.replace("[dateReg:","");
            } else if (s.startsWith("[sys:")) {
				if (s.replace("[sys:","").compareTo("{}") == 0) {
					sys = new ArrayList<String>();
				} else {
					sys = new ArrayList<String>(Arrays.asList(s.replace("[sys:{","").replace("}","").split(",")));
				}
            } else if (s.startsWith("[exKeys:")) {
                if (s.replace("[exKeys:","").compareTo("{}") == 0) {
					exKeys = new ArrayList<String>();
				} else {
					exKeys = new ArrayList<String>(Arrays.asList(s.replace("[exKeys:{","").replace("}","").split(",")));
				}
            }
        }
    }
}

public class LicenseDataReference {
    public String ver;
    public int index;

    public LicenseDataReference(String v, int i) {
        ver = v;
        index = i;
    }
}
