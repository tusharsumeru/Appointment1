import 'package:country_picker/country_picker.dart';

class PhoneValidation {
  /// Get the expected phone number length for a given Country object
  /// Uses the example property from the Country class to determine length
  static int getPhoneLengthForCountryObject(Country country) {
    // Use the example property from the Country class
    if (country.example != null && country.example!.isNotEmpty) {
      // Remove any non-digit characters from the example and get length
      final exampleDigits = country.example!.replaceAll(RegExp(r'[^\d]'), '');
      return exampleDigits.length;
    }
    
    // Return 0 if no example is available
    return 0;
  }

  /// Get the expected phone number length for a given country code
  /// Note: This method requires a Country object to work properly
  static int getPhoneLengthForCountry(String countryCode) {
    // This method is deprecated - use getPhoneLengthForCountryObject instead
    return 0;
  }

  /// Validate if a phone number has the correct length for the given country
  /// Note: This method requires a Country object to work properly
  static bool isValidPhoneLength(String phoneNumber, String countryCode) {
    // This method is deprecated - use isValidPhoneLengthForCountry instead
    return false;
  }

  /// Validate if a phone number has the correct length for the given Country object
  static bool isValidPhoneLengthForCountry(String phoneNumber, Country country) {
    final expectedLength = getPhoneLengthForCountryObject(country);
    if (expectedLength == 0) {
      // If no example is available, consider any non-empty phone number as valid
      return phoneNumber.isNotEmpty;
    }
    return phoneNumber.length == expectedLength;
  }

  /// Check if phone number is too short for the given Country object
  static bool isPhoneNumberTooShort(String phoneNumber, Country country) {
    final expectedLength = getPhoneLengthForCountryObject(country);
    if (expectedLength == 0) {
      return false; // Can't determine if too short without example
    }
    return phoneNumber.length < expectedLength;
  }

  /// Check if phone number is too long for the given Country object
  static bool isPhoneNumberTooLong(String phoneNumber, Country country) {
    final expectedLength = getPhoneLengthForCountryObject(country);
    if (expectedLength == 0) {
      return false; // Can't determine if too long without example
    }
    return phoneNumber.length > expectedLength;
  }

  /// Get validation message for phone number length
  /// Note: This method requires a Country object to work properly
  static String getPhoneValidationMessage(String countryCode) {
    return 'Please use getPhoneValidationMessageForCountry with Country object';
  }

  /// Get validation message for phone number length using Country object
  static String getPhoneValidationMessageForCountry(Country country) {
    final expectedLength = getPhoneLengthForCountryObject(country);
    if (expectedLength == 0) {
      return 'Enter a valid phone number';
    }
    return 'Phone number should be $expectedLength digits';
  }

  /// Get detailed validation message for phone number using Country object
  static String getDetailedPhoneValidationMessage(String phoneNumber, Country country) {
    final expectedLength = getPhoneLengthForCountryObject(country);
    if (expectedLength == 0) {
      return 'Enter a valid phone number';
    }
    
    if (phoneNumber.isEmpty) {
      return 'Phone number is required';
    } else if (phoneNumber.length < expectedLength) {
      return 'Phone number is too short. Expected $expectedLength digits, got ${phoneNumber.length}';
    } else if (phoneNumber.length > expectedLength) {
      return 'Phone number is too long. Expected $expectedLength digits, got ${phoneNumber.length}';
    } else {
      return 'Phone number is valid';
    }
  }

  /// Get example phone number from Country object
  static String? getExamplePhoneNumber(Country country) {
    return country.example;
  }

  /// Get formatted phone number with country code
  static String getFormattedPhoneNumber(String phoneNumber, Country country) {
    return '+${country.phoneCode}$phoneNumber';
  }
}