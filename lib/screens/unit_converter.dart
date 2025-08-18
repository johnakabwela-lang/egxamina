import 'package:flutter/material.dart';

class UnitConverterScreen extends StatefulWidget {
  const UnitConverterScreen({super.key});

  @override
  State<UnitConverterScreen> createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends State<UnitConverterScreen> {
  String selectedCategory = 'Length';
  String fromUnit = 'Meters';
  String toUnit = 'Feet';
  TextEditingController inputController = TextEditingController();
  String result = '0';
  List<String> workSteps = [];

  final Map<String, Map<String, double>> conversions = {
    'Length': {
      'Meters': 1.0,
      'Feet': 3.28084,
      'Inches': 39.3701,
      'Centimeters': 100.0,
      'Kilometers': 0.001,
      'Miles': 0.000621371,
      'Yards': 1.09361,
    },
    'Weight': {
      'Kilograms': 1.0,
      'Pounds': 2.20462,
      'Ounces': 35.274,
      'Grams': 1000.0,
      'Stones': 0.157473,
      'Tons': 0.001,
    },
    'Temperature': {
      'Celsius': 1.0,
      'Fahrenheit': 1.0,
      'Kelvin': 1.0,
    },
    'Volume': {
      'Liters': 1.0,
      'Gallons': 0.264172,
      'Milliliters': 1000.0,
      'Cups': 4.22675,
      'Pints': 2.11338,
      'Quarts': 1.05669,
      'Fluid Ounces': 33.814,
    },
  };

  final Map<String, String> unitSymbols = {
    'Meters': 'm',
    'Feet': 'ft',
    'Inches': 'in',
    'Centimeters': 'cm',
    'Kilometers': 'km',
    'Miles': 'mi',
    'Yards': 'yd',
    'Kilograms': 'kg',
    'Pounds': 'lb',
    'Ounces': 'oz',
    'Grams': 'g',
    'Stones': 'st',
    'Tons': 't',
    'Celsius': '°C',
    'Fahrenheit': '°F',
    'Kelvin': 'K',
    'Liters': 'L',
    'Gallons': 'gal',
    'Milliliters': 'mL',
    'Cups': 'cups',
    'Pints': 'pt',
    'Quarts': 'qt',
    'Fluid Ounces': 'fl oz',
  };

  @override
  void initState() {
    super.initState();
    inputController.addListener(_convertUnits);
  }

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

  void _convertUnits() {
    if (inputController.text.isEmpty) {
      setState(() {
        result = '0';
        workSteps = [];
      });
      return;
    }

    double? inputValue = double.tryParse(inputController.text);
    if (inputValue == null) return;

    double convertedValue;
    List<String> steps = [];

    if (selectedCategory == 'Temperature') {
      convertedValue = _convertTemperature(inputValue, fromUnit, toUnit, steps);
    } else {
      convertedValue =
          _convertRegularUnits(inputValue, fromUnit, toUnit, steps);
    }

    setState(() {
      result =
          convertedValue.toStringAsFixed(6).replaceAll(RegExp(r'\.?0+$'), '');
      workSteps = steps;
    });
  }

  double _convertRegularUnits(
      double value, String from, String to, List<String> steps) {
    steps.add("Converting $value ${unitSymbols[from]} to ${unitSymbols[to]}");

    double fromFactor = conversions[selectedCategory]![from]!;
    double toFactor = conversions[selectedCategory]![to]!;

    if (from == to) {
      steps.add("Same units - no conversion needed");
      steps.add("Result: $value ${unitSymbols[to]}");
      return value;
    }

    // Convert to base unit first
    double baseValue = value / fromFactor;
    steps.add("Step 1: Convert to base unit");
    steps.add(
        "$value ÷ $fromFactor = ${baseValue.toStringAsFixed(8).replaceAll(RegExp(r'\.?0+$'), '')}");

    // Convert from base unit to target
    double convertedValue = baseValue * toFactor;
    steps.add("Step 2: Convert to target unit");
    steps.add(
        "${baseValue.toStringAsFixed(8).replaceAll(RegExp(r'\.?0+$'), '')} × $toFactor = ${convertedValue.toStringAsFixed(8).replaceAll(RegExp(r'\.?0+$'), '')}");

    steps.add(
        "Final Result: ${convertedValue.toStringAsFixed(6).replaceAll(RegExp(r'\.?0+$'), '')} ${unitSymbols[to]}");

    return convertedValue;
  }

  double _convertTemperature(
      double value, String from, String to, List<String> steps) {
    steps.add("Converting $value${unitSymbols[from]} to ${unitSymbols[to]}");

    if (from == to) {
      steps.add("Same units - no conversion needed");
      steps.add("Result: $value${unitSymbols[to]}");
      return value;
    }

    // Convert to Celsius first
    double celsius;
    switch (from) {
      case 'Celsius':
        celsius = value;
        steps.add("Already in Celsius: $value°C");
        break;
      case 'Fahrenheit':
        celsius = (value - 32) * 5 / 9;
        steps.add("Step 1: Convert Fahrenheit to Celsius");
        steps.add(
            "($value - 32) × 5/9 = ${celsius.toStringAsFixed(4).replaceAll(RegExp(r'\.?0+$'), '')}°C");
        break;
      case 'Kelvin':
        celsius = value - 273.15;
        steps.add("Step 1: Convert Kelvin to Celsius");
        steps.add(
            "$value - 273.15 = ${celsius.toStringAsFixed(4).replaceAll(RegExp(r'\.?0+$'), '')}°C");
        break;
      default:
        celsius = value;
    }

    // Convert from Celsius to target
    double result;
    switch (to) {
      case 'Celsius':
        result = celsius;
        if (from != 'Celsius') {
          steps.add(
              "Final Result: ${result.toStringAsFixed(4).replaceAll(RegExp(r'\.?0+$'), '')}°C");
        }
        break;
      case 'Fahrenheit':
        result = celsius * 9 / 5 + 32;
        String stepText = from == 'Celsius' ? "Step 1" : "Step 2";
        steps.add("$stepText: Convert Celsius to Fahrenheit");
        steps.add(
            "${celsius.toStringAsFixed(4).replaceAll(RegExp(r'\.?0+$'), '')} × 9/5 + 32 = ${result.toStringAsFixed(4).replaceAll(RegExp(r'\.?0+$'), '')}°F");
        break;
      case 'Kelvin':
        result = celsius + 273.15;
        String stepText = from == 'Celsius' ? "Step 1" : "Step 2";
        steps.add("$stepText: Convert Celsius to Kelvin");
        steps.add(
            "${celsius.toStringAsFixed(4).replaceAll(RegExp(r'\.?0+$'), '')} + 273.15 = ${result.toStringAsFixed(4).replaceAll(RegExp(r'\.?0+$'), '')}K");
        break;
      default:
        result = celsius;
    }

    return result;
  }

  void _onCategoryChanged(String category) {
    setState(() {
      selectedCategory = category;
      fromUnit = conversions[category]!.keys.first;
      toUnit = conversions[category]!.keys.elementAt(1);
      _convertUnits();
    });
  }

  void _swapUnits() {
    setState(() {
      String temp = fromUnit;
      fromUnit = toUnit;
      toUnit = temp;
      _convertUnits();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF58CC02),
        foregroundColor: Colors.white,
        title: const Text('Unit Converter'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category Selection
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: conversions.keys.map((category) {
                        return ChoiceChip(
                          label: Text(category),
                          selected: selectedCategory == category,
                          onSelected: (_) => _onCategoryChanged(category),
                          selectedColor: const Color(0xFF58CC02),
                          labelStyle: TextStyle(
                            color: selectedCategory == category
                                ? Colors.white
                                : Colors.black87,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Input Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'From',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: fromUnit,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: conversions[selectedCategory]!.keys.map((unit) {
                        return DropdownMenuItem(
                          value: unit,
                          child: Text('$unit (${unitSymbols[unit]})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          fromUnit = value!;
                          _convertUnits();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: inputController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'Enter value in ${unitSymbols[fromUnit]}',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Swap Button
            Center(
              child: FloatingActionButton(
                mini: true,
                backgroundColor: const Color(0xFF58CC02),
                onPressed: _swapUnits,
                child: const Icon(
                  Icons.swap_vert,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Output Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'To',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: toUnit,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: conversions[selectedCategory]!.keys.map((unit) {
                        return DropdownMenuItem(
                          value: unit,
                          child: Text('$unit (${unitSymbols[unit]})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          toUnit = value!;
                          _convertUnits();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.grey.shade50,
                      ),
                      child: Text(
                        '$result ${unitSymbols[toUnit]}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF58CC02),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Work Steps Section
            if (workSteps.isNotEmpty) ...[
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.calculate,
                            color: Color(0xFF58CC02),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Conversion Steps',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: workSteps.asMap().entries.map((entry) {
                            int index = entry.key;
                            String step = entry.value;
                            bool isFormula = step.contains('×') ||
                                step.contains('÷') ||
                                step.contains('+') ||
                                step.contains('-');
                            bool isResult = step.startsWith('Final Result') ||
                                step.startsWith('Result:');

                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index == workSteps.length - 1 ? 0 : 8,
                              ),
                              child: Text(
                                step,
                                style: TextStyle(
                                  fontSize: isResult ? 14 : 13,
                                  fontWeight: isResult
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontFamily: isFormula ? 'monospace' : null,
                                  color: isResult
                                      ? const Color(0xFF58CC02)
                                      : isFormula
                                          ? Colors.blue.shade700
                                          : Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Quick Reference
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Available Units in $selectedCategory',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: conversions[selectedCategory]!.keys.map((unit) {
                        return Chip(
                          label: Text(
                            '${unitSymbols[unit]} - $unit',
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.grey.shade100,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
