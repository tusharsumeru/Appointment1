import 'dart:convert';

class JwtUtils {
  /// Decodes a JWT token and returns the payload as a Map
  static Map<String, dynamic>? decodeToken(String token) {
    try {
      // Split the token into parts
      final parts = token.split('.');
      if (parts.length != 3) {
        print('Invalid JWT token format');
        return null;
      }

      // Decode the payload (second part)
      final payload = parts[1];
      
      // Add padding if needed for base64 decoding
      String normalizedPayload = payload;
      switch (payload.length % 4) {
        case 0:
          break; // No padding needed
        case 2:
          normalizedPayload += '==';
          break;
        case 3:
          normalizedPayload += '=';
          break;
        default:
          print('Invalid JWT payload format');
          return null;
      }

      // Replace URL-safe characters
      normalizedPayload = normalizedPayload.replaceAll('-', '+').replaceAll('_', '/');
      
      // Decode base64
      final decodedBytes = base64Url.decode(normalizedPayload);
      final decodedString = utf8.decode(decodedBytes);
      
      // Parse JSON
      final payloadMap = json.decode(decodedString) as Map<String, dynamic>;
      
      return payloadMap;
    } catch (e) {
      print('Error decoding JWT token: $e');
      return null;
    }
  }

  /// Extracts the MongoDB ID from JWT token payload
  static String? extractMongoId(String token) {
    try {
      final payload = decodeToken(token);
      if (payload == null) {
        return null;
      }

      // Try different possible field names for MongoDB ID
      final possibleIdFields = ['_id', 'id', 'userId', 'user_id', 'sub'];
      
      for (final field in possibleIdFields) {
        if (payload.containsKey(field)) {
          final id = payload[field];
          if (id != null) {
            return id.toString();
          }
        }
      }

      print('MongoDB ID not found in JWT token payload');
      print('Available fields in payload: ${payload.keys.toList()}');
      return null;
    } catch (e) {
      print('Error extracting MongoDB ID from JWT token: $e');
      return null;
    }
  }

  /// Checks if a JWT token is expired
  static bool isTokenExpired(String token) {
    try {
      final payload = decodeToken(token);
      if (payload == null) {
        return true;
      }

      final exp = payload['exp'];
      if (exp == null) {
        return false; // No expiration set
      }

      final expirationTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final currentTime = DateTime.now();

      return currentTime.isAfter(expirationTime);
    } catch (e) {
      print('Error checking token expiration: $e');
      return true; // Assume expired if there's an error
    }
  }

  /// Gets all user information from JWT token payload
  static Map<String, dynamic>? getUserInfoFromToken(String token) {
    try {
      final payload = decodeToken(token);
      if (payload == null) {
        return null;
      }

      // Extract user information from payload
      final userInfo = <String, dynamic>{};
      
      // Common JWT payload fields
      final commonFields = [
        '_id', 'id', 'userId', 'user_id', 'sub',
        'email', 'name', 'fullName', 'firstName', 'lastName',
        'role', 'permissions', 'iat', 'exp', 'iss', 'aud'
      ];

      for (final field in commonFields) {
        if (payload.containsKey(field)) {
          userInfo[field] = payload[field];
        }
      }

      return userInfo;
    } catch (e) {
      print('Error extracting user info from JWT token: $e');
      return null;
    }
  }
} 