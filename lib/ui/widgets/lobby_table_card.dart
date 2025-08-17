import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/pitch_service.dart';

class LobbyTableCard extends StatelessWidget {
  const LobbyTableCard({
    super.key,
    required this.table,
    required this.onTap,
    required this.onQuickJoin,
  });

  final LobbyTable table;
  final VoidCallback onTap;
  final VoidCallback? onQuickJoin;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  table.inProgress ? Icons.play_arrow : Icons.hourglass_empty,
                  color: table.inProgress ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    table.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildVariantChip(),
                _buildStatusChip(),
                _buildOccupancyChip(),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (onQuickJoin != null && !table.inProgress && table.seatsTaken < table.seatsTotal)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onQuickJoin,
                      icon: const Icon(Icons.flash_on, size: 16),
                      label: const Text('Quick Join'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (onQuickJoin != null && !table.inProgress && table.seatsTaken < table.seatsTotal)
                  const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.visibility, size: 16),
                    label: Text(table.inProgress ? 'View' : 'Join'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantChip() {
    final is10Point = table.variant == '10_point';
    return Chip(
      label: Text(is10Point ? '10-Point' : '4-Point'),
      backgroundColor: is10Point ? Colors.blue[100] : Colors.purple[100],
      labelStyle: TextStyle(
        color: is10Point ? Colors.blue[700] : Colors.purple[700],
        fontSize: 12,
      ),
    );
  }

  Widget _buildStatusChip() {
    return Chip(
      label: Text(table.inProgress ? 'PLAYING' : 'OPEN'),
      backgroundColor: table.inProgress ? Colors.orange[100] : Colors.green[100],
      labelStyle: TextStyle(
        color: table.inProgress ? Colors.orange[700] : Colors.green[700],
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildOccupancyChip() {
    final ratio = table.seatsTaken / table.seatsTotal;
    Color backgroundColor;
    Color textColor;

    if (ratio >= 1.0) {
      backgroundColor = Colors.red[100]!;
      textColor = Colors.red[700]!;
    } else if (ratio >= 0.5) {
      backgroundColor = Colors.orange[100]!;
      textColor = Colors.orange[700]!;
    } else {
      backgroundColor = Colors.green[100]!;
      textColor = Colors.green[700]!;
    }

    return Chip(
      label: Text('${table.seatsTaken}/${table.seatsTotal}'),
      backgroundColor: backgroundColor,
      labelStyle: TextStyle(
        color: textColor,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}