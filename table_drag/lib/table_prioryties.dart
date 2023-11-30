import 'package:flutter/material.dart';

class PageData {
  int page;
  int totalPage;
  int? pageSize;
  int totalElement;

  PageData({
    required this.pageSize,
    required this.totalPage,
    required this.page,
    required this.totalElement,
  });
}

class ItemHeaderTable {
  String key;
  double? width; // chiều rộng content
  double flex; // tỉ lệ chiều rộng content
  Alignment alignment; // Vị trí hiển thị content view
  bool hideIsSmallScreen; // View nhỏ ẩn (true: ẩn, false: không ẩn)
  bool hideColumn; // ẩn hiện view(true: ẩn, false: không ẩn)
  Widget? child;
  bool validate;

  ItemHeaderTable({
    this.child,
    this.width,
    this.flex = 1,
    this.hideColumn = false,
    this.hideIsSmallScreen = false,
    this.validate = true,
    required this.key,
    this.alignment = Alignment.topLeft,
  });

  ItemHeaderTable clone({Widget? child, double? width, bool? hideColumn, double? flex}){
    return ItemHeaderTable(
      key: key,
      child: child ?? this.child,
      flex: flex ?? this.flex,
      hideColumn: hideColumn ?? this.hideColumn,
      hideIsSmallScreen: hideIsSmallScreen,
      alignment: alignment,
      width: width ?? this.width,
      validate: validate,
    );
  }


}