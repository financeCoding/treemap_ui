import 'dart:html';
import 'dart:math';
import 'dart:async';
import 'package:treemap/treemap.dart';
import '../resources/test_resources.dart';

const controllsContainerId = "controllsContainer";
const treemapContainerId = "treemapContainer";
const prefixDataModel = "dataModel";
const initialSize = 525;
const min = "10";
const max = "1300";
const step = "1";

RangeInputElement widthSlider;
RangeInputElement heightSlider;
ButtonElement resetModelButton = new ButtonElement();
Element treemapContainer;
SelectElement algorithmSelect;
Map<String, LayoutAlgorithm> algorithmMap = initAlgorithmMap();
SelectElement modelSelect;
CheckboxInputElement randomSizeCheckbox = new CheckboxInputElement();
CheckboxInputElement randomPropertyCheckbox = new CheckboxInputElement();
Map<String, DataModel> modelMap = initModelMap();
Timer sizeUpdateTimer = new Timer(0,(_){});
NumberInputElement sizeUpdateInput = new NumberInputElement();
Timer propertyUpdateTimer =  new Timer(0,(_){});
NumberInputElement propertyUpdateInput = new NumberInputElement();
Treemap treemap;

List<LayoutAlgorithm> algorithms = TestResources.layoutAlgorithms;

main() {
  prepareDocument("dynamic test");
  modelSelect.value = "dataModel2";

  widthSlider.onChange.listen((e) {
    var size = widthSlider.valueAsNumber;
    treemapContainer.style.width = "${size}px";
  });
  heightSlider.onChange.listen((e) {
    var size = heightSlider.valueAsNumber;
    treemapContainer.style.height = "${size}px";
  });
  algorithmSelect.onChange.listen((e) {
    treemap.layoutAlgorithm = selectedAlgorithm();
  });
  modelSelect.onChange.listen((e) {
    treemap.model = selectedModel();
  });
  randomSizeCheckbox.onChange.listen((e) {
    sizeUpdateTimer = new Timer.repeating(sizeUpdateInput.valueAsNumber.toInt(),randomSizeFunction);
  });
  randomPropertyCheckbox.onChange.listen((e) {
    propertyUpdateTimer = new Timer.repeating(propertyUpdateInput.valueAsNumber.toInt(),randomPropertyFunction);
  });
  sizeUpdateInput.onChange.listen((e) {
    sizeUpdateTimer.cancel();
    sizeUpdateTimer = new Timer.repeating(sizeUpdateInput.valueAsNumber.toInt(),randomSizeFunction);
  });
  propertyUpdateInput.onChange.listen((e) {
    propertyUpdateTimer.cancel();
    propertyUpdateTimer = new Timer.repeating(propertyUpdateInput.valueAsNumber.toInt(),randomPropertyFunction);
  });
  resetModelButton.onClick.listen((e) {
    final index = int.parse(modelSelect.value.substring(prefixDataModel.length));
    final tmp = TestResources.testDataModels.elementAt(index);
    final model = tmp.isBranch ? tmp as Branch : tmp as Leaf;
    final copy = model.copy();
    modelMap["${prefixDataModel}${index}"] = copy;
    treemap.model = selectedModel();
  });
  
  treemap = new Treemap(treemapContainer, selectedModel(), algorithm : selectedAlgorithm());    
}

void prepareDocument(String documentTitle) {
  document.title = documentTitle;
  final controllsContainer = new Element.html("<div id=${controllsContainerId}></div>");
  treemapContainer = new Element.html("<div id=${treemapContainerId} style='width:${initialSize}px;height:${initialSize}px;'></div>");
  widthSlider = new RangeInputElement();
  widthSlider
     ..min = min
     ..max = max
     ..value = initialSize.toString()
     ..step = step;
  heightSlider = new RangeInputElement();
  heightSlider
     ..min = min
     ..max = max
     ..value = initialSize.toString()
     ..step = step;
  resetModelButton.text = "reset";
  resetModelButton.title = "Resets the selected model";
  final sizeControls = new DivElement();
  sizeControls..append(widthSlider)..append(heightSlider);
  final dynamicSizeLabel = new Element.html("<span> random size updates every </span>");
  randomSizeCheckbox.style.verticalAlign = "middle";
  randomSizeCheckbox.checked = false;
  final sizeUpdateLabel = new Element.html("<span> ms</span>");
  sizeUpdateInput..min = "100"..max = "10000"..step = "100"..valueAsNumber = 200;
  final dynamicSizeControls = new DivElement();
  dynamicSizeControls..append(randomSizeCheckbox)..append(dynamicSizeLabel)..append(sizeUpdateInput)..append(sizeUpdateLabel);
  final dynamicPropertyLabel = new Element.html("<span> random property updates every </span>");
  randomPropertyCheckbox.style.verticalAlign = "middle";
  randomPropertyCheckbox.checked = false;
  final propertyUpdateLabel = new Element.html("<span> ms</span>");
  propertyUpdateInput..min = "1"..max = "10000"..step = "10"..valueAsNumber = 50;
  final dynamicPropertyControls = new DivElement();
  dynamicPropertyControls..append(randomPropertyCheckbox)..append(dynamicPropertyLabel)..append(propertyUpdateInput)..append(propertyUpdateLabel);
  var options = algorithmMap.keys.map((k) => "<option>$k</option>").reduce("", (acc,e) => "$acc$e");
  algorithmSelect = new Element.html("<select>$options</select>");
  options = modelMap.keys.map((k) => "<option>$k</option>").reduce("", (acc,e) => "$acc$e");
  modelSelect = new Element.html("<select>$options</select>");
  controllsContainer
    ..append(algorithmSelect)
    ..append(modelSelect)
    ..append(resetModelButton)
    ..append(dynamicSizeControls)
    ..append(dynamicPropertyControls)
    ..append(sizeControls);
  document.body
    ..append(controllsContainer)
    ..append(treemapContainer);
}

LayoutAlgorithm selectedAlgorithm() {
  return algorithmMap[algorithmSelect.value];
}

DataModel selectedModel() {
  return modelMap[modelSelect.value];
}

Map<String, DataModel> initModelMap() {
  var i = 0;
  var map = new Map();
  TestResources.testDataModels.forEach((model) {
    map["${prefixDataModel}${i++}"] = model.copy();
  });
  return map;
}

Map<String, LayoutAlgorithm> initAlgorithmMap() {
  var map = new Map();
  TestResources.layoutAlgorithms.forEach((alg) {
    map["${alg.runtimeType.toString().toLowerCase()}"] = alg;
  });
  return map;
}

final randomSizeFunction = (Timer timer) {
  final Random r = new Random();
  if (randomSizeCheckbox.checked) {
    final leafes = leafesOnly(selectedModel());
    final leaf = leafes.elementAt(r.nextInt(leafes.length));
    leaf.size = r.nextInt(1000);      
  } else {
    timer.cancel();
  }
};

final randomPropertyFunction = (Timer timer) {
  final Random r = new Random();
  if (randomPropertyCheckbox.checked) {
    final leafes = leafesOnly(selectedModel());
    final leaf = leafes.elementAt(r.nextInt(leafes.length));
    leaf.someProperty = r.nextInt(1000); 
  } else {
    timer.cancel();
  }
};

List<Leaf> leafesOnly(DataModel model) {
  final List<AbstractLeaf> result = [];
  if (model.isLeaf) {
    result.add(model);
  } else {
    final branch = model as AbstractBranch;
    branch.children.map((child) => leafesOnly(child)).forEach((x) => result.addAll(x));
  }
  return result;
}
