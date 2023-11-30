// ignore_for_file: must_be_immutable
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'menu_context.dart';
import 'table_prioryties.dart';
import 'text_custom.dart';

abstract class TableNewDesign extends StatefulWidget {
  TableNewDesign({
    super.key,
    this.filterWidget,
    this.colorBackground,
    this.filterPadding,
    this.filterColumn,
    this.showSettingTable = true,
    this.isLoading = false,
    this.isEmptyData = false,
    this.headerBackGround,
    this.widthSmallScreen = 1200,
    this.minimumColumnWidth = 100,
    this.styleHeader = const TextStyle(color: Colors.black, fontWeight: FontWeight.w400, fontSize: 14),
  }){
    headerBackGround ??= Colors.indigo.withOpacity(0.5);
  }

  List<ItemHeaderTable> genHeader();

  List<Map<String, Widget>> genDataTable();

  bool showSettingTable;

  Widget? filterWidget;

  EdgeInsets? filterPadding;

  EdgeInsets? filterColumn;

  Color? colorBackground;
  
  Color? headerBackGround;


  Color? colorHover;

  bool? isLoading;

  bool isEmptyData;
  
  TextStyle styleHeader;

  double widthSmallScreen;

  double minimumColumnWidth;

  void changePage(int page);

  @override
  State<TableNewDesign> createState() => _TableNewDesignState();
}

class _TableNewDesignState extends State<TableNewDesign> {
  double initX = 0;

  double initXCategories = 0;

  bool firstTime = true;

  List<ItemHeaderTable> headerData = [];

  List<ItemHeaderTable> headerDataDefault = []; // lưu thông tin hiển thị mặc định của bảng

  bool changeNumberColumn = false;

  final double borderTable =0.5;

  List<Map<String, Widget>> tableData = [];

  int page = 0;

  int totalPage = 0;

  int totalElement = 0;

  double maxWidth = 0;

  double? maxOldWidth;

  double maxHeight = 0;

  double totalFlex = 0;

  double currentFlex = 0;

  final verticalScrollController = ScrollController();

  final horizontalScrollController = ScrollController();

  final double sizePadding = 8;

  Map<String, double> mapWidthRow = {};

  late MenuContext menuContext;
  GlobalKey keyParent = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  Widget headerWidget(BuildContext context) {
    List<Widget> listHeaderItem = [];
    int countColumn =0;
    for (int index = 0; index < headerData.length; index++) {
      if (!headerData[index].hideColumn) {
        Widget itemResize = const SizedBox.shrink();
        if (index != headerData.length - 1 && countColumn < numberColumnShow()-1) {
          itemResize = iconResize(index);
        }
        countColumn++;
        Widget itemHeader = widgetContentHeader(index);
        listHeaderItem.add(itemHeader);
        listHeaderItem.add(itemResize);
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: widget.headerBackGround,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: listHeaderItem,
      ),
    );
  }

  // Icon thay đổi độ rộng các cột
  Widget iconResize(int index) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        onPanStart: (details) {
          initX = details.globalPosition.dx;
          setState(() {});
        },
        onPanUpdate: (details) {
          final increment = details.globalPosition.dx - initX;
          final newWidth = mapWidthRow[headerData[index].key]! + increment;
          initX = details.globalPosition.dx;
          resizeWidthColumn(newWidth, index);
        },
        child: Container(
          width: sizePadding,
          color: widget.headerBackGround,
          child: Center(
            child: Container(
              height: 20,
              width: 0.2,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  // widget header
  Widget widgetContentHeader(int index) {
    double width = widget.minimumColumnWidth;
    if(headerData[index].width != null){
      width = headerData[index].width!;
    }
    else if(widget.minimumColumnWidth < (mapWidthRow[headerData[index].key]??0)){
      width = mapWidthRow[headerData[index].key]!;
    }
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: sizePadding / 2),
      child: Align(
        alignment: headerData[index].alignment,
        child: headerData[index].child ??
            Text(
              headerData[index].key,
              style: widget.styleHeader,
              textAlign: headerData[index].alignment == Alignment.center ? TextAlign.center : TextAlign.start,
            ),
      ),
    );
  }

  // check số cột đang hiển thị
  int numberColumnShow() {
    int numberColumn = 0;
    for (var value in headerData) {
      if (!value.hideColumn) {
        numberColumn++;
      }
    }
    return numberColumn;
  }

  // tính max width còn lại
  double currentWidthFlex(double maxWidth) {
    currentFlex = double.parse(totalFlex.toString());
    double width = (numberColumnShow() - 1) * sizePadding;
    for (var value in headerData) {
      if (value.width != null && !value.hideColumn) {
        width += value.width!;
      }
    }
    double widthFlex = maxWidth - width;
    this.maxWidth = widthFlex;
    for (int index = 0; index < headerData.length; index++) {
      if (headerData[index].width == null && !headerData[index].hideColumn) {
        double widthRow = (headerData[index].flex / totalFlex) * widthFlex;
        if (widthRow < widget.minimumColumnWidth) {
          width += widget.minimumColumnWidth;
          currentFlex -= headerData[index].flex;
        }
      }
    }
    return (maxWidth - width)/currentFlex;
  }

  // tính tổng số flex
  double getMaxFlex() {
    double totalFlex = 0;
    for (var value in headerData) {
      if (value.width == null && !value.hideColumn && value.validate) {
        totalFlex += value.flex;
      }
    }
    return totalFlex;
  }

  /*
  tính toán độ rộng của row
    1. vẽ lần đầu
    2. thay đổi kích thước màn hình
      resize != 0 Thay đổi kích thước trình duyệt vẽ lại
      resize < 0 phóng to kích thước trình duyệt
    3. thay đổi số lượng cột
   */
  void genMapWidthRow(double totalWidth, {double resize = 0}) {
    double currentWidth = currentWidthFlex(totalWidth);
    if (mapWidthRow.isEmpty || resize != 0 || changeNumberColumn) {
      changeNumberColumn = false;
      for (int index = 0; index < headerData.length; index++) {
        if (!headerData[index].hideColumn) {
          if (headerData[index].width != null) {
            // Nếu setWidth cho column thì lấy kích thước = Width
            mapWidthRow[headerData[index].key] = headerData[index].width!;
          } else {
            // Nếu width column nhỏ hơn minWidth thì lấy minWidth
            double width = (headerData[index].flex / totalFlex) * maxWidth;
            if (width > widget.minimumColumnWidth && currentFlex > 0) {
              mapWidthRow[headerData[index].key] = headerData[index].flex * currentWidth;
            } else {
              mapWidthRow[headerData[index].key] = widget.minimumColumnWidth;
            }
          }
        }
      }
    }
  }

  Widget rowWidget(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(tableData.length, (indexRow) {
          List<Widget> lstItemRow = [];
          if (tableData[indexRow].length == 1) {
            lstItemRow.add(tableData[indexRow].values.first);
          } else {
            int countColumn =0;
            for (int indexKey = 0; indexKey < headerData.length; indexKey++) {
              if (!headerData[indexKey].hideColumn) {
                double width = widget.minimumColumnWidth;
                if(headerData[indexKey].width != null){
                  width = headerData[indexKey].width!;
                }
                else if(widget.minimumColumnWidth < (mapWidthRow[headerData[indexKey].key]??0)){
                  width = mapWidthRow[headerData[indexKey].key]!;
                }
                Widget paddingResize = const SizedBox.shrink();
                if (indexKey != headerData.length - 1 &&  countColumn < numberColumnShow()-1) {
                  paddingResize = Container(width: sizePadding);
                }
                countColumn++;
                lstItemRow.add(
                  Container(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      width: width,
                      child: Align(
                          alignment: headerData[indexKey].alignment,
                          child: tableData[indexRow][headerData[indexKey].key]!)),
                );
                lstItemRow.add(paddingResize);
              }
            }
          }

          return OnHoverWidget(builder: (isHover) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(indexRow == tableData.length-1 ? 8: 0)),
                color: isHover ? widget.colorHover : (indexRow % 2 == 0 ? Colors.white : Colors.black12)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: lstItemRow,
              ),
            );
          });
        })
      ],
    );
  }

  Widget viewEmptyData(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            headerWidget(context),
            widget.isLoading! && !widget.isEmptyData ? Container(
                constraints: const BoxConstraints(
                    minHeight: 600
                )):
            Container(
              constraints: const BoxConstraints(
                  minHeight: 600
              ),
              child: TextCustom("no_data"),
            ),
          ],
        ),
      ),
    );
  }

  //Tính toán co kéo độ rộng cốt
  void resizeWidthColumn(double newWidth, int indexResize) {
    if ((mapWidthRow[headerData[indexResize].key]! <= widget.minimumColumnWidth && newWidth < widget.minimumColumnWidth) || headerData[indexResize].width !=null) {
      return;
    }
    // Đếm số lượng cột có thể thay đổi kích thước
    double numberFlex = 0;
    for (int i = indexResize + 1; i < headerData.length; i++) {
      if(!headerData[i].hideColumn){
        if (newWidth - mapWidthRow[headerData[indexResize].key]! > 0) {
          if (headerData[i].width == null && mapWidthRow[headerData[i].key]! > widget.minimumColumnWidth) {
            numberFlex++;
          }
        } else {
          if (headerData[i].width == null) {
            numberFlex++;
          }
        }
      }
    }
    if (numberFlex > 0) {
      bool update = false;
      double widthOverlord = 0;
      double sizeBonus = (newWidth - mapWidthRow[headerData[indexResize].key]!) / numberFlex;
      // set kích thước lại cho các cột ở sau
      for (int i = indexResize + 1; i < headerData.length; i++) {
        if(!headerData[i].hideColumn){
          if (newWidth - mapWidthRow[headerData[indexResize].key]! > 0) { // trường hợp kéo rộng cột
            // check cột ở sau có được thay đổi kích thước hay không
            if (headerData[i].width == null && mapWidthRow[headerData[i].key]! > widget.minimumColumnWidth) {
              if(mapWidthRow[headerData[i].key]! - sizeBonus < widget.minimumColumnWidth){
                widthOverlord += widget.minimumColumnWidth - (mapWidthRow[headerData[i].key]! - sizeBonus);
                mapWidthRow[headerData[i].key] = widget.minimumColumnWidth;
              }else{
                mapWidthRow[headerData[i].key] = mapWidthRow[headerData[i].key]! - sizeBonus;
              }
              update = true;
            }
          } else { // trường hợp
            if (newWidth > widget.minimumColumnWidth) { // trường hợp thu nhỏ cột
              if (headerData[i].width == null) {
                mapWidthRow[headerData[i].key] = mapWidthRow[headerData[i].key]! - sizeBonus;
              }
              update = true;
            }
          }
        }
      }
      if (update) {
        mapWidthRow[headerData[indexResize].key] = newWidth - widthOverlord;
        setState(() {});
      }
    }
  }

  List<ItemHeaderTable> genDataHeader(List<ItemHeaderTable> headerData, {double maxWidth=0}) {
    List<ItemHeaderTable> data = [];
    data = [
      ...headerData.map((e) {
        ItemHeaderTable item = e.clone();
        if (item.hideIsSmallScreen && maxWidth < widget.widthSmallScreen && firstTime && item.validate) {
          item.hideColumn = true;
        }
        return item;
      })
    ];
    return data;
  }

  //Gen data của table
  void genDataTable(double maxWidth) {
    checkRefreshTable();
    if (headerData.isEmpty) {
      headerData = genDataHeader(widget.genHeader(), maxWidth: maxWidth);
      firstTime = false;
      headerDataDefault = headerData;
    }else{
      for (int i = 0; i< headerData.length; i++) {
        if(headerData[i].child !=null){
          widget.genHeader().forEach((value) {
            if(headerData[i].key == value.key){
              headerData[i] = value.clone(width: headerData[i].width, hideColumn: headerData[i].hideColumn);
            }
          });
        }
      }}
    tableData = widget.genDataTable();
    totalFlex = getMaxFlex();
  }

  void checkRefreshTable(){
    List<String> currentLstKey =[];
    for (var element in headerData) {
      if(element.validate){
        currentLstKey.add(element.key);
      }
    }

    List<String> newLstKey =[];
    for (var element in genDataHeader(widget.genHeader())) {
      if(element.validate){
        newLstKey.add(element.key);
      }
    }

    for (var element in genDataHeader(widget.genHeader())) {
      if(newLstKey.length != currentLstKey.length|| ( element.validate && !currentLstKey.contains(element.key))){
        headerData = [];
        firstTime = true;
        mapWidthRow.clear();
      }
    }
  }

  //tính toán kích thước của từng row
  void calculatorSizeRow(double width) {
    maxOldWidth ??= width;
    double resize = maxOldWidth! - width;
    if (resize != 0) {
      maxOldWidth = width;
    }
    genMapWidthRow(width, resize: resize);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      //Gen data của table
      return SizedBox(
        width: constraints.maxWidth,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                  color: widget.colorBackground?? Colors.transparent,
                  borderRadius: BorderRadius.circular(8)
              ),
              child: Column(
                children: [
                  widget.filterWidget != null
                      ? Padding(
                    padding: widget.filterColumn ?? EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: widget.filterWidget!),
                        // Tạm Ẩn filter
                        widget.showSettingTable ? Container(
                          margin: widget.filterPadding,
                          child: InkWell(
                            key: keyParent,
                            onTap: () {
                              menuContext = MenuContext(context,
                                  childWidget: FilterTable(
                                    headerData: headerData,
                                    headerDataDefault: headerDataDefault,
                                    confirm: (List<ItemHeaderTable> headerData) {
                                      this.headerData = headerData;
                                      changeNumberColumn = true;
                                      setState(() {});
                                      menuContext.dismiss();
                                    },
                                    dismiss: () {
                                      menuContext.dismiss();
                                    },
                                    oldMaxWidth: maxOldWidth ?? 0,
                                  ),
                                  parentPaddingRight: 90,
                                  height: 400,
                                  width: 320,
                                  backgroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                  borderRadius: BorderRadius.circular(8),
                                  onDismiss: () {});
                              menuContext.show(
                                widgetKey: keyParent,
                              );
                            },
                            child: Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8), color: Colors.white),
                              child: Align(
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.settings,
                                    color: Colors.black,
                                    size: 14,
                                  )),
                            ),
                          ),
                        ): const SizedBox.shrink()
                      ],
                    ),
                  )
                      : const SizedBox.shrink(),
                  LayoutBuilder(builder: (BuildContext context, BoxConstraints constraintsTable) {
                    //Gen data của table
                    genDataTable(constraintsTable.maxWidth-0.5);
                    //tính toán kích thước của từng row
                    calculatorSizeRow(constraintsTable.maxWidth-0.5);
                    return tableData.isEmpty
                        ? viewEmptyData(context)
                        : Container(
                      width: constraintsTable.maxWidth,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            spreadRadius: 0,
                            blurRadius: 19,
                            offset: const Offset(0, 5),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            spreadRadius: 0,
                            blurRadius: 56,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Scrollbar(
                        thumbVisibility: true,
                        trackVisibility: true,
                        controller: horizontalScrollController,
                        child: SingleChildScrollView(
                          controller: horizontalScrollController,
                          scrollDirection: Axis.horizontal,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              headerWidget(context),
                              rowWidget(context),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class FilterTable extends StatefulWidget {
  FilterTable({
    Key? key,
    required this.headerData,
    required this.headerDataDefault,
    required this.dismiss,
    required this.confirm,
    required this.oldMaxWidth,
  }) : super(key: key);
  List<ItemHeaderTable> headerData;
  List<ItemHeaderTable> headerDataDefault;
  Function() dismiss;
  Function(List<ItemHeaderTable>) confirm;
  double oldMaxWidth;

  @override
  State<FilterTable> createState() => _FilterTableState();
}

class _FilterTableState extends State<FilterTable> {
  @override
  void initState() {
    headerData = [...widget.headerData.map((e) => e.clone()).toList()];
    super.initState();
  }

  List<ItemHeaderTable> headerData = [];
  final scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 16),
      height: 400,
      width: 320,
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.only(left: 16),
                    child: const Text(
                      "setting_table",
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w400, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      Transform.scale(
                        scale: 0.5,
                        child: CupertinoSwitch(
                          value: validate(),
                          onChanged: (value) {
                            for (var element in headerData) {
                              element.hideColumn = !value;
                            }
                            setState(() {});
                          },
                          activeColor: Colors.indigo,
                        ),
                      ),
                      const Expanded(
                          child: Text(
                            "select_all",
                            style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w400),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.only(right: 16),
              child: InkWell(
                onTap: () {
                  headerData = [...widget.headerDataDefault.map((e) => e.clone()).toList()];
                  widget.confirm(headerData);
                },
                child: Container(
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      "set_default",
                      style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w400).copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )),
              ),
            )
          ],
        ),
        Divider(
          color: Colors.indigo.withOpacity(0.5).withOpacity(0.05),
          height: 0.5,
        ),
        SizedBox( width:8),
        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            trackVisibility: true,
            controller: scrollController,
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...List.generate(headerData.length, (index) {
                    return InkWell(
                      onTap: () {
                        headerData[index].hideColumn = !headerData[index].hideColumn;
                        setState(() {});
                      },
                      child: Container(
                        padding: EdgeInsets.only(left: 8),
                        child: Row(
                          children: [
                            Transform.scale(
                              scale: 0.8,
                              child: Checkbox(
                                splashRadius: 8,
                                checkColor: Colors.white,
                                activeColor: Colors.indigo.withOpacity(0.5),
                                value: !headerData[index].hideColumn,
                                onChanged: (value) {
                                  headerData[index].hideColumn = !headerData[index].hideColumn;
                                  setState(() {});
                                },
                              ),
                            ),
                            Expanded(
                                child: Text(
                                  headerData[index].key,
                                  style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w400),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ))
                          ],
                        ),
                      ),
                    );
                  })
                ],
              ),
            ),
          ),
        ),
        Divider(
          color: Colors.indigo.withOpacity(0.5).withOpacity(0.05),
          height: 0.5,
        ),
        SizedBox( width:8),
        Container(
          height: 56,
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
          ),
          child: Center(
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      widget.dismiss();
                    },
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                          color: Colors.indigo.withOpacity(0.5).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8)),
                      child: Align(
                        alignment: Alignment.center,
                        child: Text("cancel",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.indigo.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w400),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox( width:16),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (validate()) {
                        widget.confirm(headerData);
                      }
                    },
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                          color: validate() ? Colors.indigo.withOpacity(0.5) : Colors.grey,
                          borderRadius: BorderRadius.circular(8)),
                      child: Align(
                        alignment: Alignment.center,
                        child: Text("confirm",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600).copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  bool validate() {
    bool success = false;
    for (var element in headerData) {
      if (!element.hideColumn) {
        success = true;
        break;
      }
    }
    return success;
  }
}

// Cách sử dụng
// OnHover( builder: (bool isHovered) {
// final color = isHovered ? Colors.red : Colors.black;
// return child);

class OnHoverWidget extends StatefulWidget {

  final Widget Function(bool isHovered) builder;
  bool ?isHovered = false;

  OnHoverWidget({Key? key, required this.builder, this.isHovered}) : super(key: key);

  @override
  OnHoverWidgetState createState() => OnHoverWidgetState();
}

class OnHoverWidgetState extends State<OnHoverWidget> {


  @override
  Widget build(BuildContext context) {

    return MouseRegion(
      onEnter: (_)=> onEntered(true),
      onExit: (_)=> onEntered(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        child: widget.builder(widget.isHovered??false),
      ),
    );
  }

  void onEntered(bool isHovered){
    setState(() {
      widget.isHovered = isHovered;
    });
  }
}