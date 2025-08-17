import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/pitch_service.dart';
import '../table_screen.dart';

class LobbyTableCard extends StatelessWidget {
  const LobbyTableCard({
    super.key,
    required this.table,
    this.onQuickJoin,
  });

  final LobbyTable table;
  final VoidCallback? onQuickJoin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with table name and status icon
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
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Chips row for variant, status, and occupancy
            Wrap(
              spacing: 8,
              children: [
                // Variant chip
                Chip(
                  label: Text(
                    table.variant == '10_point' ? '10-Point' : '4-Point',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: table.variant == '10_point' 
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.purple.withOpacity(0.1),
                  side: BorderSide(
                    color: table.variant == '10_point' 
                        ? Colors.blue 
                        : Colors.purple,
                    width: 1,
                  ),
                ),
                
                // Status chip
                Chip(
                  label: Text(
                    table.status.toUpperCase(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: _getStatusColor(table.status).withOpacity(0.1),
                  side: BorderSide(
                    color: _getStatusColor(table.status),
                    width: 1,
                  ),
                ),
                
                // Occupancy chip
                Chip(
                  label: Text(
                    '${table.seatsTaken}/${table.seatsTotal}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: _getOccupancyColor(table.seatsTaken, table.seatsTotal).withOpacity(0.1),
                  side: BorderSide(
                    color: _getOccupancyColor(table.seatsTaken, table.seatsTotal),
                    width: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Action buttons row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Quick join button (only show for mock and open tables with available seats)
                if (onQuickJoin != null && 
                    table.status == 'open' && 
                    table.seatsTaken < table.seatsTotal) ...[
                  ElevatedButton.icon(
                    onPressed: onQuickJoin,
                    icon: const Icon(Icons.flash_on, size: 16),
                    label: const Text('Quick Join'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                
                // View/Join button
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => TableScreen(tableId: table.id, name: table.name),
                    ));
                  },
                  child: Text(table.inProgress ? 'View' : 'Join'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.green;
      case 'playing':
        return Colors.blue;
      case 'full':
        return Colors.orange;
      case 'closed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getOccupancyColor(int taken, int total) {
    final ratio = taken / total;
    if (ratio < 0.5) return Colors.red;
    if (ratio < 1.0) return Colors.orange;
    return Colors.green;
  }
}