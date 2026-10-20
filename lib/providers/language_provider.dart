import 'package:flutter/material.dart';
import '../core/storage/secure_storage_service.dart';

enum AppLanguage {
  en('en', 'English', 'English'),
  mr('mr', 'मराठी', 'Marathi'),
  hi('hi', 'हिंदी', 'Hindi');

  final String code;
  final String nativeName;
  final String englishName;

  const AppLanguage(this.code, this.nativeName, this.englishName);

  static AppLanguage fromCode(String? code) {
    switch (code) {
      case 'mr':
        return AppLanguage.mr;
      case 'hi':
        return AppLanguage.hi;
      default:
        return AppLanguage.en;
    }
  }
}

class LanguageProvider extends ChangeNotifier {
  final SecureStorageService _storage = SecureStorageService();
  AppLanguage _currentLanguage = AppLanguage.en;

  AppLanguage get currentLanguage => _currentLanguage;
  String get languageCode => _currentLanguage.code;
  String get localeCode => _currentLanguage.code;
  String get currentLocaleName => _currentLanguage.nativeName;

  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'mr': 'मराठी (Marathi)',
    'hi': 'हिंदी (Hindi)',
  };

  Future<void> setLocale(String code) async {
    await setLanguage(AppLanguage.fromCode(code));
  }

  String translate(String key) => tr(key);

  Future<void> loadLanguage() async {
    try {
      final code = await _storage.getLanguage();
      if (code != null && code.isNotEmpty) {
        _currentLanguage = AppLanguage.fromCode(code);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setLanguage(AppLanguage lang) async {
    if (_currentLanguage != lang) {
      _currentLanguage = lang;
      notifyListeners();
      try {
        await _storage.saveLanguage(lang.code);
      } catch (_) {}
    }
  }

  // ── Localized String Lookups ──────────────────────────────────
  String tr(String key) {
    final map = _localizedStrings[key];
    if (map == null) return key;
    return map[_currentLanguage.code] ?? map['en'] ?? key;
  }

  static const Map<String, Map<String, String>> _localizedStrings = {
    // Navigation
    'nav_home': {
      'en': 'Home',
      'mr': 'मुख्यपृष्ठ',
      'hi': 'होम',
    },
    'nav_plants': {
      'en': 'Plants',
      'mr': 'वनस्पती',
      'hi': 'पौधे',
    },
    'nav_nurseries': {
      'en': 'Nurseries',
      'mr': 'रोपवाटिका',
      'hi': 'नर्सरी',
    },
    'nav_ai': {
      'en': 'AI Doctor',
      'mr': 'एआय मार्गदर्शक',
      'hi': 'एआई गाइड',
    },

    // Header & Actions
    'app_title': {
      'en': 'GoGreen-AI',
      'mr': 'गो-ग्रीन एआय',
      'hi': 'गो-ग्रीन एआई',
    },
    'my_orders': {
      'en': 'My Orders',
      'mr': 'माझ्या ऑर्डर्स',
      'hi': 'मेरे ऑर्डर्स',
    },
    'cart': {
      'en': 'Shopping Cart',
      'mr': 'खरेदी कार्ट',
      'hi': 'शॉपिंग कार्ट',
    },
    'wishlist': {
      'en': 'Wishlist',
      'mr': 'आवडते (Wishlist)',
      'hi': 'पसंदीदा (Wishlist)',
    },
    'care_reminders': {
      'en': 'Care Reminders',
      'mr': 'काळजी स्मरणपत्रे',
      'hi': 'देखभाल रिमाइंडर',
    },
    'change_language': {
      'en': 'Change Language',
      'mr': 'भाषा बदला',
      'hi': 'भाषा बदलें',
    },
    'logout': {
      'en': 'Log Out',
      'mr': 'लॉग आउट करा',
      'hi': 'लॉग आउट करें',
    },

    // Search & Filter
    'search_plants_hint': {
      'en': 'Search plants by name, variety…',
      'mr': 'नावाने किंवा प्रकाराने वनस्पती शोधा…',
      'hi': 'नाम या प्रजाति से पौधे खोजें…',
    },
    'all_plants': {
      'en': 'All Plants',
      'mr': 'सर्व वनस्पती',
      'hi': 'सभी पौधे',
    },
    'indoor': {
      'en': 'Indoor',
      'mr': 'घरातील (Indoor)',
      'hi': 'घर के अंदर (Indoor)',
    },
    'outdoor': {
      'en': 'Outdoor',
      'mr': 'बागेतील (Outdoor)',
      'hi': 'बाहर के (Outdoor)',
    },
    'medicinal': {
      'en': 'Medicinal 🌿',
      'mr': 'औषधी वनस्पती 🌿',
      'hi': 'औषधीय पौधे 🌿',
    },
    'flowering': {
      'en': 'Flowering',
      'mr': 'फुलांची झाडे',
      'hi': 'फूलों वाले',
    },
    'succulents': {
      'en': 'Succulents',
      'mr': 'सक्युलंट्स',
      'hi': 'सक्युलेंट्स',
    },

    // Nurseries
    'nearby_nurseries': {
      'en': 'Nearby Nurseries',
      'mr': 'जवळपासच्या रोपवाटिका',
      'hi': 'आसपास की नर्सरी',
    },
    'list_view': {
      'en': 'List View',
      'mr': 'यादी दृश्य',
      'hi': 'सूची दृश्य',
    },
    'map_view': {
      'en': 'Map Discovery',
      'mr': 'नकाशा शोध',
      'hi': 'मानचित्र खोज',
    },
    'locate_me': {
      'en': 'Locate Me',
      'mr': 'माझे स्थान शोधा',
      'hi': 'मेरा स्थान खोजें',
    },
    'verified_nursery': {
      'en': 'Verified Nursery',
      'mr': 'प्रमाणित रोपवाटिका',
      'hi': 'सत्यापित नर्सरी',
    },
    'open_directions': {
      'en': 'Get Directions',
      'mr': 'दिशानिर्देश मिळवा',
      'hi': 'दिशा-निर्देश प्राप्त करें',
    },
    'call_nursery': {
      'en': 'Call Nursery',
      'mr': 'कॉल करा',
      'hi': 'कॉल करें',
    },
    'whatsapp_inquiry': {
      'en': 'WhatsApp',
      'mr': 'व्हॉट्सअ‍ॅप',
      'hi': 'व्हाट्सएप',
    },

    // Gallery Category Cards inside Nursery Storefront
    'gallery_indoor': {
      'en': 'Indoor Houseplants',
      'mr': 'घरातील शोभिवंत झाडे',
      'hi': 'घर के अंदर के पौधे',
    },
    'gallery_outdoor': {
      'en': 'Outdoor Garden Plants',
      'mr': 'बागेतील व अंगणातील वनस्पती',
      'hi': 'बगीचे व बाहरी पौधे',
    },
    'gallery_medicinal': {
      'en': 'Medicinal / Aushadhi 🌿',
      'mr': 'औषधी व आयुर्वेदिक वनस्पती 🌿',
      'hi': 'औषधीय व आयुर्वेदिक पौधे 🌿',
    },
    'gallery_general': {
      'en': 'General & Grounds',
      'mr': 'रोपवाटिका परिसर व इतर',
      'hi': 'नर्सरी परिसर व अन्य',
    },

    // Plant Detail & Cart
    'add_to_cart': {
      'en': 'Add to Cart',
      'mr': 'कार्टमध्ये जोडा',
      'hi': 'कार्ट में जोड़ें',
    },
    'buy_now': {
      'en': 'Buy Now',
      'mr': 'आत्ताच खरेदी करा',
      'hi': 'अभी खरीदें',
    },
    'in_stock': {
      'en': 'In Stock',
      'mr': 'उपलब्ध आहे',
      'hi': 'उपलब्ध है',
    },
    'out_of_stock': {
      'en': 'Out of Stock',
      'mr': 'उपलब्ध नाही',
      'hi': 'स्टॉक समाप्त',
    },
    'care_reminder_btn': {
      'en': 'Set Care & Watering Reminder',
      'mr': 'पाणी व काळजी स्मरणपत्र लावा',
      'hi': 'पानी व देखभाल रिमाइंडर लगाएं',
    },

    // Payment & Razorpay
    'payment_method': {
      'en': 'Payment Method',
      'mr': 'पैसे देण्याची पद्धत',
      'hi': 'भुगतान का तरीका',
    },
    'razorpay_title': {
      'en': 'Razorpay Online (UPI, Cards, Netbanking)',
      'mr': 'रेझरपे ऑनलाइन (यूपीआय, कार्ड्स, नेटबँकिंग)',
      'hi': 'रेज़रपे ऑनलाइन (यूपीआई, कार्ड, नेटबैंकिंग)',
    },
    'razorpay_badge': {
      'en': 'Instant Verification & Security',
      'mr': 'त्वरित पडताळणी व सुरक्षित',
      'hi': 'त्वरित सत्यापन एवं सुरक्षित',
    },
    'pay_at_pickup': {
      'en': 'Pay at Pickup',
      'mr': 'पिकअपच्या वेळी पैसे द्या',
      'hi': 'पिकअप पर भुगतान करें',
    },
    'cod': {
      'en': 'Cash on Delivery',
      'mr': 'कॅश ऑन डिलिव्हरी',
      'hi': 'कैश ऑन डिलीवरी',
    },
    'upi_manual': {
      'en': 'Nursery UPI QR (Manual Verification)',
      'mr': 'रोपवाटिका यूपीआय क्यूआर (मॅन्युअल तपासणी)',
      'hi': 'नर्सरी यूपीआई क्यूआर (मैन्युअल सत्यापन)',
    },
    'place_order': {
      'en': 'Place Order',
      'mr': 'ऑर्डर निश्चित करा',
      'hi': 'ऑर्डर दर्ज करें',
    },
    'pay_securely': {
      'en': 'Pay Securely via Razorpay',
      'mr': 'रेझरपे द्वारे सुरक्षित पेमेंट करा',
      'hi': 'रेज़रपे द्वारा सुरक्षित भुगतान करें',
    },

    // Order Confirmation Dialog
    'order_placed_title': {
      'en': 'Order Placed!',
      'mr': 'ऑर्डर नोंदवली गेली!',
      'hi': 'ऑर्डर दर्ज हो गया!',
    },
    'order_id_label': {
      'en': 'Order ID',
      'mr': 'ऑर्डर क्रमांक',
      'hi': 'ऑर्डर संख्या',
    },
    'customer_name_label': {
      'en': 'Customer Name',
      'mr': 'ग्राहकाचे नाव',
      'hi': 'ग्राहक का नाम',
    },
    'nursery_name_label': {
      'en': 'Nursery Name',
      'mr': 'रोपवाटिकेचे नाव',
      'hi': 'नर्सरी का नाम',
    },
    'plant_name_label': {
      'en': 'Plant Name',
      'mr': 'वनस्पतीचे नाव',
      'hi': 'पौधे का नाम',
    },
    'quantity_label': {
      'en': 'Quantity',
      'mr': 'प्रमाण (Quantity)',
      'hi': 'मात्रा',
    },
    'price_label': {
      'en': 'Price',
      'mr': 'दर (किंमत)',
      'hi': 'मूल्य (कीमत)',
    },
    'total_amount_label': {
      'en': 'Total Amount',
      'mr': 'एकूण रक्कम',
      'hi': 'कुल राशि',
    },
    'payment_status_label': {
      'en': 'Payment Status',
      'mr': 'पेमेंट स्थिती',
      'hi': 'भुगतान स्थिति',
    },
    'payment_verified_paid': {
      'en': 'Payment Successful (Verified via Razorpay)',
      'mr': 'पेमेंट यशस्वी (रेझरपे द्वारे पडताळणी पूर्ण)',
      'hi': 'भुगतान सफल (रेज़रपे द्वारा सत्यापित)',
    },
    'payment_awaiting_verification': {
      'en': 'Payment submitted — awaiting verification',
      'mr': 'पेमेंट सबमिट केले — पडताळणी प्रलंबित',
      'hi': 'भुगतान जमा — सत्यापन लंबित',
    },
    'payment_pending_pickup': {
      'en': 'Pending (To be paid at nursery pickup)',
      'mr': 'प्रलंबित (रोपवाटिकेत पिकअप करताना द्या)',
      'hi': 'लंबित (नर्सरी पर पिकअप के समय देय)',
    },
    'payment_pending_cod': {
      'en': 'Pending (Cash on Delivery)',
      'mr': 'प्रलंबित (डिलिव्हरीच्या वेळी द्या)',
      'hi': 'लंबित (कैश ऑन डिलीवरी)',
    },
    'continue_shopping': {
      'en': 'Continue Shopping',
      'mr': 'खरेदी सुरू ठेवा',
      'hi': 'खरीदारी जारी रखें',
    },
    'view_my_orders': {
      'en': 'View My Orders',
      'mr': 'माझ्या ऑर्डर्स पहा',
      'hi': 'मेरे ऑर्डर्स देखें',
    },
  };
}
