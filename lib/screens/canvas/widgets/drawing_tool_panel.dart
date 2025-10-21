import 'package:flutter/material.dart';



class DrawingToolPanel extends StatelessWidget {

  final Color selectedColor;

  final double strokeWidth;

  final bool hasDrawings;

  final bool hasSelection;

  final Function(Color) onColorChanged;

  final Function(double) onStrokeWidthChanged;

  final VoidCallback onUndo;

  final VoidCallback onDeleteSelected;



  const DrawingToolPanel({

    super.key,

    required this.selectedColor,

    required this.strokeWidth,

    required this.hasDrawings,

    required this.hasSelection,

    required this.onColorChanged,

    required this.onStrokeWidthChanged,

    required this.onUndo,

    required this.onDeleteSelected,

  });



  @override

  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: Colors.grey.shade300),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        mainAxisSize: MainAxisSize.min,

        children: [

          const Text(

            'Drawing Tools',

            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),

          ),

          const SizedBox(height: 12),



          // Instructions

          Container(

            padding: const EdgeInsets.all(8),

            decoration: BoxDecoration(

              color: Colors.blue.shade50,

              borderRadius: BorderRadius.circular(6),

            ),

            child: Row(

              children: [

                Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),

                const SizedBox(width: 8),

                Expanded(

                  child: Text(

                    'Draw on canvas. Tap a drawing to select it.',

                    style: TextStyle(fontSize: 11, color: Colors.blue.shade700),

                  ),

                ),

              ],

            ),

          ),

          const SizedBox(height: 16),



          // Color Picker

          const Text('Color', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),

          const SizedBox(height: 8),

          Wrap(

            spacing: 8,

            runSpacing: 8,

            children: [

              _buildColorButton(Colors.black),

              _buildColorButton(Colors.red),

              _buildColorButton(Colors.blue),

              _buildColorButton(Colors.green),

              _buildColorButton(Colors.orange),

              _buildColorButton(Colors.purple),

              _buildColorButton(const Color(0xFF8B4513)), // Brown

              _buildColorButton(Colors.pink),

            ],

          ),

          const SizedBox(height: 16),



          // Stroke Width

          const Text('Thickness', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),

          Row(

            children: [

              Expanded(

                child: Slider(

                  value: strokeWidth,

                  min: 1,

                  max: 10,

                  divisions: 9,

                  label: strokeWidth.round().toString(),

                  onChanged: onStrokeWidthChanged,

                ),

              ),

              SizedBox(

                width: 30,

                child: Text(

                  strokeWidth.round().toString(),

                  style: const TextStyle(fontWeight: FontWeight.bold),

                ),

              ),

            ],

          ),

          const SizedBox(height: 8),



          // Preview

          Container(

            height: 40,

            decoration: BoxDecoration(

              color: Colors.grey.shade100,

              borderRadius: BorderRadius.circular(8),

            ),

            child: Center(

              child: Container(

                width: 60,

                height: strokeWidth,

                decoration: BoxDecoration(

                  color: selectedColor,

                  borderRadius: BorderRadius.circular(strokeWidth / 2),

                ),

              ),

            ),

          ),

          const SizedBox(height: 16),



          // Action Buttons

          OutlinedButton.icon(

            onPressed: hasDrawings ? onUndo : null,

            icon: const Icon(Icons.undo, size: 16),

            label: const Text('Undo Last', style: TextStyle(fontSize: 12)),

            style: OutlinedButton.styleFrom(

              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),

            ),

          ),

          const SizedBox(height: 8),

          OutlinedButton.icon(

            onPressed: hasSelection ? onDeleteSelected : null,

            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),

            label: const Text('Delete Selected', style: TextStyle(fontSize: 12, color: Colors.red)),

            style: OutlinedButton.styleFrom(

              side: const BorderSide(color: Colors.red),

              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),

            ),

          ),

        ],

      ),

    );

  }



  Widget _buildColorButton(Color color) {

    final isSelected = selectedColor == color;

    return GestureDetector(

      onTap: () => onColorChanged(color),

      child: Container(

        width: 32,

        height: 32,

        decoration: BoxDecoration(

          color: color,

          shape: BoxShape.circle,

          border: Border.all(

            color: isSelected ? Colors.blue : Colors.grey.shade400,

            width: isSelected ? 3 : 1,

          ),

          boxShadow: isSelected

              ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 4, spreadRadius: 1)]

              : null,

        ),

        child: isSelected

            ? const Icon(Icons.check, color: Colors.white, size: 16)

            : null,

      ),

    );

  }

}
