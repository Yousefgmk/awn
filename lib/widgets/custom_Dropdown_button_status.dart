// Custom Dropdown widget
import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

final List<String> categories = [
  'Homeworks',
  'Exams',
  'Getting to a place',
];

class CustomDropdownButtonStatus extends StatefulWidget {
  CustomDropdownButtonStatus({
    super.key,
    required this.controller,
    required this.selectedDropDownValue,
    this.isUser = true,
    this.isFilter = false,
    required this.onChanged,
  });

  final TextEditingController controller;
  String? selectedDropDownValue;
  final bool isUser;
  final bool isFilter;
  final Function(String?) onChanged;

  @override
  State<CustomDropdownButtonStatus> createState() => _CustomDropdownButtonStatusState();
}

class _CustomDropdownButtonStatusState extends State<CustomDropdownButtonStatus> {
  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        hint: Row(
          children: [
            const Icon(
              Icons.list,
              size: 16,
              color: Colors.black,
            ),
            const SizedBox(
              width: 4,
            ),
            Expanded(
              child: Text(
                widget.isFilter ? 'filter' : 'category',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        items: categories
            .map((category) => DropdownMenuItem<String>(
                  value: category,
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ))
            .toList(),
        value: widget.selectedDropDownValue,
        onChanged: (value) {
          setState(() {
            widget.selectedDropDownValue = value;
          });
          widget.onChanged(value);
        },
        buttonStyleData: ButtonStyleData(
          height: 50,
          width: 160,
          padding: const EdgeInsets.only(left: 14, right: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.black26,
            ),
            color: widget.isUser
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.secondary,
          ),
          elevation: 2,
        ),
        iconStyleData: const IconStyleData(
          icon: Icon(
            Icons.arrow_forward_ios_outlined,
          ),
          iconSize: 14,
          iconEnabledColor: Colors.black,
          iconDisabledColor: Colors.grey,
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: 200,
          width: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: widget.isUser
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.secondary,
          ),
          offset: const Offset(-20, 0),
          scrollbarTheme: ScrollbarThemeData(
            radius: const Radius.circular(40),
            thickness: MaterialStateProperty.all(6),
            thumbVisibility: MaterialStateProperty.all(true),
          ),
        ),
        menuItemStyleData: const MenuItemStyleData(
          height: 40,
          padding: EdgeInsets.only(left: 14, right: 14),
        ),
        dropdownSearchData: DropdownSearchData(
          searchController: widget.controller,
          searchInnerWidgetHeight: 50,
          searchInnerWidget: Container(
            height: 50,
            padding: const EdgeInsets.only(
              top: 8,
              bottom: 4,
              right: 8,
              left: 8,
            ),
            child: TextFormField(
              expands: true,
              maxLines: null,
              controller: widget.controller,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                hintText: "Search",
                hintStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          searchMatchFn: (item, searchValue) {
            return item.value.toString().toLowerCase().contains(searchValue);
          },
        ),
        onMenuStateChange: (isOpen) {
          if (!isOpen) {
            widget.controller.clear();
          }
        },
      ),
    );
  }
}
