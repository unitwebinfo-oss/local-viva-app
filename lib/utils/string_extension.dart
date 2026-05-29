extension StringExtension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  String toSentenceCase() {
    if (isEmpty) return this;
    // Split by paragraphs (double newline or single newline)
    final paragraphs = split('\n');
    final formatted = paragraphs.map((paragraph) {
      final trimmed = paragraph.trim();
      if (trimmed.isEmpty) return trimmed;
      // Capitalize first letter of paragraph, lowercase rest
      final first = trimmed[0].toUpperCase();
      final rest = trimmed.substring(1).toLowerCase();
      // Also capitalize after sentence-ending punctuation followed by space
      final sentences = '$first$rest'.split(RegExp(r'(?<=[.!?])\s+'));
      return sentences.map((s) {
        final st = s.trim();
        if (st.isEmpty) return s;
        return '${st[0].toUpperCase()}${st.substring(1)}';
      }).join(' ');
    }).join('\n');
    return formatted;
  }
}
