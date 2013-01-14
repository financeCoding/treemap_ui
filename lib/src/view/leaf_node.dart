part of treemap_view;

class LeafNode extends Node {
  
  LeafNode(model, width, height, orientation) :
    super._internal(model,width,height,orientation) {
    _content = container;
    _content.style..padding = "0px"
        ..backgroundColor = "#DDD";
    _content.append(_nodeLabel);
    container.style.border = _borderStyle;
  }
  
  List<Node> get children => [];
}