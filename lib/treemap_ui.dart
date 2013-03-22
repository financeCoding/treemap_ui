library treemap_ui;

import 'dart:html' hide Node;
import 'dart:async';
import 'src/model/treemap_ui_model.dart';
export 'src/model/treemap_ui_model.dart';
import 'src/view/treemap_ui_view.dart';
export 'src/view/treemap_ui_view.dart' show TreemapStyle, Orientation, Color;
import 'src/layout/treemap_ui_layout.dart';
export 'src/layout/treemap_ui_layout.dart';

class Treemap{
  
   TreemapStyle _style;
   final DivElement componentRoot;
   LayoutAlgorithm _layoutAlgorithm;
   DataModel _dataModel;
   StyleElement _currentActiveStyle;
   Node _rootNode;
   StreamSubscription<num> _modelChangeSubscription;
   bool isTraversable = true;
   bool showTooltips = true;
   bool automaticRepaints = true;

   Treemap(DivElement this.componentRoot, DataModel this._dataModel, 
           LayoutAlgorithm this._layoutAlgorithm, [TreemapStyle this._style]) {
     if (componentRoot == null || _dataModel == null || _layoutAlgorithm == null) {
       throw nullError;
     }
     if (_style == null) {
       _style = new TreemapStyle();
     }
     _validateComponentRoot(componentRoot);
     _registerModelChangeSubscription();
     _registerStyleUpdateSubscription();
     _setTreemapStyle();
     repaint();
   }

   void repaint() {
     ViewModel viewModel;
     if (_rootNode != null) {
       _rootNode.cancelSubscriptions();
       viewModel = _rootNode.viewModel;
     } else {
       viewModel = new ViewModel(this);
     }
     _rootNode = new Node.forRoot(model, viewModel);
     componentRoot.children.clear();
     componentRoot.append(_rootNode.container);
     if (_rootNode.isBranch) {
       layoutAlgorithm.layout(_rootNode);
     }
     viewModel.rootNode = _rootNode;
   }

   DataModel get model => _dataModel;

   set model(DataModel model) {
     if (model == null) {
       throw nullError;
     }
     _dataModel = model;
     _registerModelChangeSubscription();
     if (automaticRepaints) {
       repaint();
     }
   }

   LayoutAlgorithm get layoutAlgorithm => _layoutAlgorithm;

   set layoutAlgorithm(LayoutAlgorithm algorithm) {
     if (algorithm == null) {
       throw nullError;
     }
     _layoutAlgorithm = algorithm;
     if (automaticRepaints) {
       repaint();
     }
   }

   TreemapStyle get style => _style;

   void _registerModelChangeSubscription() {
     if (_modelChangeSubscription != null) {
       _modelChangeSubscription.cancel();
     }
     _modelChangeSubscription = _dataModel.onStructuralChange.listen((_) {
       if (automaticRepaints) {
         repaint();
       }
     });
   }

   void _registerStyleUpdateSubscription() {
     style.onChange.listen((_) {
         _setTreemapStyle();
         repaint();
     });
   }

   void _setTreemapStyle() {
     final StyleElement sty = style.inlineStyle;
     if (_currentActiveStyle != null) {
       document.head.children.remove(_currentActiveStyle);
     }
     final styleOrLinkElements = document.head.children.where((e) => e.runtimeType == StyleElement || e.runtimeType == LinkElement);
     if (styleOrLinkElements.isEmpty) {
       document.head.append(sty);
     } else {
       styleOrLinkElements.first.insertAdjacentElement('beforeBegin', sty);
     }
     _currentActiveStyle = sty;
   }

   void _validateComponentRoot(DivElement element) {
     if (element.client.height <= 0) {
       throw new ArgumentError("The <div> element has to have a height greater than zero and must be attached to the document");
     }
     if (element.children.length > 0) {
       throw new ArgumentError("Do not add any extra elements to the <div> element");
     }
   }
}