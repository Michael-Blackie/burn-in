class_name NumFormat

const SUFFIXES: Array[String] = ["", "K", "M", "B", "T", "Qa", "Qi"]

static func short(n: float) -> String:
	if n < 1000.0:
		return str(int(n))

	var tier := 0
	# 999.95 rather than 1000, so 999,950 becomes "1.00M" instead of "1000K"
	while n >= 999.95 and tier < SUFFIXES.size() - 1:
		n /= 1000.0
		tier += 1

	# 3 significant figures keeps the width steady: 1.23M, 12.3M, 123M
	var s: String
	if n < 10.0:
		s = "%.2f" % n
	elif n < 100.0:
		s = "%.1f" % n
	else:
		s = "%.0f" % n
	return s + SUFFIXES[tier]