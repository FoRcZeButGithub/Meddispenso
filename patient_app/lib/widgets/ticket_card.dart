import 'package:flutter/material.dart';


class TicketCard extends StatelessWidget {
final String? titleTopLeft; // e.g. unit : 1
final String? subtitle; // e.g. Medicine : Paracetamol
final Widget child;
const TicketCard({super.key, this.titleTopLeft, this.subtitle, required this.child});


@override
Widget build(BuildContext context) {
return Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: Colors.grey.shade300,
borderRadius: BorderRadius.circular(16),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
if (titleTopLeft != null)
Text(titleTopLeft!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
if (subtitle != null) ...[
const SizedBox(height: 4),
Text(subtitle!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
],
const SizedBox(height: 12),
child,
],
),
);
}
}