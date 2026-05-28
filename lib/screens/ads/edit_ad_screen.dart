import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../config/api_config.dart';
import '../../models/ad_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/storage_helper.dart';
import '../../utils/theme.dart';

class EditAdScreen extends StatefulWidget {
  final AdModel ad;

  const EditAdScreen({
    super.key,
    required this.ad,
  });

  @override
  State<EditAdScreen> createState() => _EditAdScreenState();
}

class _EditAdScreenState extends State<EditAdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cepController = TextEditingController();
  
  String? _selectedCategoryId;
  String? _selectedCondition;
  String? _selectedCity;
  String? _selectedState;
  String? _cep;
  String? _address;
  String? _neighborhood;
  bool _negotiable = false;
  List<String> _imagePaths = [];
  bool _isLoading = false;
  bool _isSearchingCep = false;

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _mainCategories = [];
  List<Map<String, dynamic>> _subcategories = [];
  String? _selectedMainCategoryId;
  String? _selectedSubcategoryId;

  @override
  void initState() {
    super.initState();
    // Load data safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadCategories().then((_) {
          if (mounted) {
            _loadAdData();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    _cepController.dispose();
    super.dispose();
  }

  Future<void> _loadAdData() async {
    try {
      // Load complete ad data from API with timeout
      final response = await ApiService.get('${ApiConfig.ads}/${widget.ad.id}')
          .timeout(const Duration(seconds: 10));
      
      if (kDebugMode) {
        print('=== LOADING COMPLETE AD DATA ===');
        print('Response: $response');
      }
      
      if (response['success'] == true && response['ad'] != null) {
        final adData = response['ad'];
        
        // Load ad data from API response
        _titleController.text = adData['title'] ?? '';
        _descriptionController.text = adData['description'] ?? '';
        
        // Handle price formatting
        double price = double.parse(adData['price'].toString());
        _priceController.text = price.toStringAsFixed(2).replaceAll('.', ',');
        
        _negotiable = adData['negotiable'] == 1 || adData['negotiable'] == true;
        _selectedCondition = adData['condition_type'];
        _selectedCity = adData['city'];
        _selectedState = adData['state'];
        _cep = adData['cep'];
        _address = adData['address'];
        _neighborhood = adData['neighborhood'];
        _cepController.text = adData['cep'] ?? '';
        
        // Load phone field - simplified logic
        if (kDebugMode) {
          print('=== PHONE DEBUG ===');
          print('Phone from API: ${adData['phone']}');
          print('Seller phone from API: ${adData['seller_phone']}');
          print('All API data: ${adData.keys}');
        }
        
        // Try API phone first, then seller phone, then fallback
        String phone = adData['phone'] ?? adData['seller_phone'] ?? widget.ad.phone ?? '';
        
        // Clean phone formatting for display (remove non-digits)
        String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
        _phoneController.text = cleanPhone; // Store clean digits, formatter will format on display
        
        if (kDebugMode) {
          print('Final phone used: "$phone"');
          print('Phone controller set to: "${_phoneController.text}"');
        }
        
        // Set category ID
        _selectedCategoryId = adData['category_id']?.toString() ?? '';
        
        // Load all images from API response
        if (adData['images'] != null && adData['images'].isNotEmpty) {
          _imagePaths = (adData['images'] as List)
              .map((img) {
                String imagePath = img['image_path']?.toString() ?? img['url']?.toString() ?? '';
                if (imagePath.startsWith('http')) {
                  return imagePath; // Already a full URL
                } else {
                  return '${ApiConfig.imageProxyUrl}?path=$imagePath'; // Use proxy
                }
              })
              .where((url) => url.isNotEmpty)
              .toList();
              
          if (kDebugMode) {
            print('Loaded ${_imagePaths.length} images from API: $_imagePaths');
          }
        } else {
          if (kDebugMode) {
            print('No images found in API response');
          }
        }
        
        if (kDebugMode) {
          print('=== AD DATA LOADED FROM API ===');
          print('Title: ${_titleController.text}');
          print('Category ID: $_selectedCategoryId');
          print('Images: $_imagePaths');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading complete ad data: $e');
      }
      // Fallback to widget data
      _titleController.text = widget.ad.title;
      _descriptionController.text = widget.ad.description;
      _priceController.text = widget.ad.price.toStringAsFixed(2).replaceAll('.', ',');
      _negotiable = widget.ad.negotiable;
      _selectedCondition = widget.ad.conditionType;
      _selectedCity = widget.ad.city;
      _selectedState = widget.ad.state;
      _cep = widget.ad.cep;
      _address = widget.ad.address;
      _neighborhood = widget.ad.neighborhood;
      _cepController.text = widget.ad.cep ?? '';
      _selectedCategoryId = widget.ad.categoryId?.toString() ?? '';
    }
    
    // Set initial categories after ad data is loaded
    _setInitialCategories();
    if (kDebugMode) {
      print('Loading ad data for edit:');
      print('Title: ${widget.ad.title}');
      print('Category ID: ${widget.ad.categoryId}');
      print('Category Name: ${widget.ad.categoryName}');
      print('City: ${widget.ad.city}');
      print('State: ${widget.ad.state}');
      print('Phone: ${widget.ad.phone}');
      print('CEP: ${widget.ad.cep}');
      print('Address: ${widget.ad.address}');
      print('=== IMAGES DEBUG ===');
      print('Raw images: ${widget.ad.images}');
      print('Images type: ${widget.ad.images.runtimeType}');
      print('Images length: ${widget.ad.images.length}');
      print('Primary image URL: ${widget.ad.primaryImageUrl}');
      print('Primary image path: ${widget.ad.primaryImagePath}');
      for (int i = 0; i < widget.ad.images.length; i++) {
        print('Image $i: ${widget.ad.images[i]}');
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      if (kDebugMode) {
        print('=== LOADING CATEGORIES ===');
        print('API URL: ${ApiConfig.categories}');
      }
      
      final response = await ApiService.get(ApiConfig.categories);
      
      if (kDebugMode) {
        print('=== CATEGORIES API RESPONSE ===');
        print('Response Type: ${response.runtimeType}');
        print('Response Keys: ${response.keys.toList()}');
        print('Success: ${response['success']}');
        print('Categories exists: ${response.containsKey('categories')}');
        print('Categories: ${response['categories']}');
        print('Categories Type: ${response['categories'].runtimeType}');
        if (response['categories'] is List) {
          print('Categories Length: ${(response['categories'] as List).length}');
          for (int i = 0; i < (response['categories'] as List).length && i < 5; i++) {
            final cat = response['categories'][i];
            print('Category $i: ID=${cat['id']}, Name=${cat['name']}, Parent=${cat['parent_id']}, Status=${cat['status']}');
          }
          
          // Check if ID 102 exists
          final category102 = (response['categories'] as List).where((cat) => cat['id'] == 102).toList();
          print('Category 102 found: ${category102.isNotEmpty}');
          if (category102.isNotEmpty) {
            print('Category 102 data: ${category102.first}');
          }
        }
      }
      
      if (response['success'] == true && response['categories'] != null) {
        final List<Map<String, dynamic>> mainCategories = [];
        final List<Map<String, dynamic>> subcategories = [];
        
        // Process flat list
        if (response['categories'] is List) {
          for (final category in response['categories']) {
            if (category == null) continue;
            
            final categoryData = {
              'id': category['id'],
              'name': category['name']?.toString() ?? '',
              'parent_id': category['parent_id'],
              'status': category['status']?.toString() ?? '',
            };
            
            if (category['parent_id'] == null) {
              mainCategories.add(categoryData);
            } else {
              subcategories.add(categoryData);
            }
          }
        }
        
        if (kDebugMode) {
          print('=== CATEGORY LOADING RESULTS ===');
          print('Main Categories Found: ${mainCategories.length}');
          print('Subcategories Found: ${subcategories.length}');
          for (int i = 0; i < mainCategories.length && i < 3; i++) {
            final main = mainCategories[i];
            print('Main $i: ID=${main['id']}, Name=${main['name']}');
          }
          for (int i = 0; i < subcategories.length && i < 3; i++) {
            final sub = subcategories[i];
            print('Sub $i: ID=${sub['id']}, Name=${sub['name']}, Parent=${sub['parent_id']}');
          }
        }
        
        if (mounted) {
          setState(() {
            _mainCategories = mainCategories;
            _subcategories = subcategories;
          });
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('=== CATEGORIES API ERROR ===');
        print('Error: $e');
        print('Stack Trace: $stackTrace');
        print('API URL: ${ApiConfig.categories}');
      }
    }
  }

  List<Map<String, dynamic>> get _filteredSubcategories {
    if (_selectedMainCategoryId == null) return [];
    
    return _subcategories
        .where((sub) => sub['parent_id']?.toString() == _selectedMainCategoryId)
        .toList();
  }

  void _onMainCategoryChanged(String? value) {
    setState(() {
      _selectedMainCategoryId = value;
      _selectedSubcategoryId = null; // Reset subcategory when main changes
    });
  }

  void _onSubcategoryChanged(String? value) {
    setState(() {
      _selectedSubcategoryId = value;
    });
  }

  void _setInitialCategories() {
    if (widget.ad == null) {
      if (kDebugMode) {
        print('Error: widget.ad is null in _setInitialCategories');
      }
      return;
    }
    
    if (kDebugMode) {
      print('=== SET INITIAL CATEGORIES ===');
      print('Ad Category ID: ${widget.ad!.categoryId}');
      print('Main Categories: ${_mainCategories.length}');
      print('Subcategories: ${_subcategories.length}');
    }
    
    // First try to find as subcategory
    final currentSubcategory = _subcategories
        .where((sub) => sub['id']?.toString() == widget.ad!.categoryId.toString())
        .firstOrNull;
    
    if (kDebugMode) {
      print('Current Subcategory: $currentSubcategory');
    }
    
    if (currentSubcategory != null) {
      // Set main category based on subcategory's parent
      _selectedSubcategoryId = currentSubcategory['id']?.toString();
      _selectedMainCategoryId = currentSubcategory['parent_id']?.toString();
      
      if (kDebugMode) {
        print('Set as subcategory:');
        print('  Main: $_selectedMainCategoryId');
        print('  Sub: $_selectedSubcategoryId');
      }
    } else {
      // If no subcategory found, try to find as main category
      final mainCategory = _mainCategories
          .where((main) => main['id']?.toString() == widget.ad!.categoryId.toString())
          .firstOrNull;
      
      if (kDebugMode) {
        print('Main Category Found: $mainCategory');
        print('Looking for ID: ${widget.ad!.categoryId.toString()}');
        print('Available Main IDs: ${_mainCategories.map((m) => m['id']).toList()}');
      }
      
      if (mainCategory != null) {
        _selectedMainCategoryId = mainCategory['id']?.toString();
        
        if (kDebugMode) {
          print('Set as main category: $_selectedMainCategoryId');
        }
      } else {
        // If still not found, this might be an orphan category or data issue
        if (kDebugMode) {
          print('WARNING: Category ID ${widget.ad!.categoryId} not found in main or subcategories!');
          print('This might be an orphan category or data inconsistency.');
        }
        
        // As a fallback, try to set the first main category
        if (_mainCategories.isNotEmpty) {
          _selectedMainCategoryId = _mainCategories.first['id']?.toString();
          if (kDebugMode) {
            print('Fallback: Set to first main category: $_selectedMainCategoryId');
          }
        }
      }
    }
    
    // Trigger setState to update UI
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _searchCep(String cep) async {
    if (cep.length < 8) return;
    
    setState(() {
      _isSearchingCep = true;
    });

    try {
      final response = await ApiService.get('/cep?cep=$cep');
      
      if (kDebugMode) {
        print('CEP Response: $response');
        print('Response type: ${response.runtimeType}');
      }
      
      if (response != null && response is Map) {
        if (response['success'] == true && response['data'] != null) {
          final data = response['data'];
          if (kDebugMode) {
            print('CEP Data: $data');
          }
          setState(() {
            _address = data['logradouro']?.toString() ?? '';
            _neighborhood = data['bairro']?.toString() ?? '';
            _selectedCity = data['localidade']?.toString() ?? '';
            _selectedState = data['uf']?.toString() ?? '';
            _cep = data['cep']?.toString() ?? '';
          });
        } else {
          _showError(response['error']?.toString() ?? 'CEP não encontrado');
        }
      } else {
        _showError('Resposta inválida do servidor');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Erro ao buscar CEP: $e');
        print('Stack trace: $stackTrace');
      }
      _showError('Erro ao buscar CEP: ${e.toString()}');
    } finally {
      setState(() {
        _isSearchingCep = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildImageGallery() {
    if (kDebugMode) {
      print('=== BUILDING IMAGE GALLERY ===');
      print('Current _imagePaths: $_imagePaths');
      print('Image paths length: ${_imagePaths.length}');
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fotos do Anúncio',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _imagePaths.length + 1,
            itemBuilder: (context, index) {
              if (index == _imagePaths.length) {
                // Add new image button
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    onTap: _addImage,
                    child: const Center(
                      child: Icon(
                        Icons.add,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                );
              }
              
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      // Image with error handling
                      Image.network(
                        _imagePaths[index],
                        width: 100,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 100,
                            height: 120,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                                size: 32,
                              ),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 100,
                            height: 120,
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                      ),
                      // Remove button
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _addImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      
      // Show dialog to choose image source
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Adicionar Imagem'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Câmera'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Galeria'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );
      
      if (source == null) return;
      
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 85,
      );
      
      if (image != null) {
        if (kDebugMode) {
          print('Image selected: ${image.path}');
        }
        
        // Upload image to server
        await _uploadImage(image);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error picking image: $e');
      }
      _showError('Erro ao selecionar imagem');
    }
  }

  Future<void> _uploadImage(XFile image) async {
    try {
      if (kDebugMode) {
        print('=== UPLOAD DEBUG START ===');
        print('Image path: ${image.path}');
        print('Image name: ${image.name}');
        print('Image size: ${await image.length()} bytes');
        print('Upload URL: ${ApiConfig.baseUrl}/upload');
      }
      
      // Get token
      final token = await StorageHelper.getToken();
      if (kDebugMode) {
        print('Token available: ${token != null ? 'YES' : 'NO'}');
        print('Token length: ${token?.length ?? 0}');
      }
      
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/upload'),
      );
      
      // Add headers
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
        request.headers['X-Auth-Token'] = token;
        request.headers['X-API-Token'] = token;
      }
      
      if (kDebugMode) {
        print('Request headers: ${request.headers}');
        print('Request method: ${request.method}');
        print('Request URL: ${request.url}');
      }
      
      // Add image file
      final imageBytes = await image.readAsBytes();
      if (kDebugMode) {
        print('Image bytes read: ${imageBytes.length} bytes');
        print('Image type: ${image.mimeType ?? 'unknown'}');
      }
      
      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: image.name,
      );
      request.files.add(multipartFile);
      
      if (kDebugMode) {
        print('Files in request: ${request.files.length}');
        print('File field name: ${request.files.first.field}');
        print('File filename: ${request.files.first.filename}');
        print('File content type: ${request.files.first.contentType}');
        print('Sending upload request...');
      }
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (kDebugMode) {
        print('Upload response: ${response.statusCode}');
        print('Upload body: ${response.body}');
      }
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          String imageUrl = responseData['url'];
          if (kDebugMode) {
            print('Image uploaded successfully: $imageUrl');
          }
          
          // Convert to proxy URL if it's a direct upload URL
          String proxiedUrl = imageUrl;
          if (imageUrl.startsWith('https://localviva.com.br/uploads/')) {
            String relativePath = imageUrl.replaceFirst('https://localviva.com.br/uploads/', '');
            proxiedUrl = '${ApiConfig.imageProxyUrl}?path=$relativePath';
            if (kDebugMode) {
              print('Converted to proxy URL: $proxiedUrl');
            }
          }
          
          setState(() {
            _imagePaths.add(proxiedUrl);
          });
          
          _showError('Imagem adicionada com sucesso!');
        } else {
          _showError('Erro no upload: ${responseData['error']}');
        }
      } else {
        _showError('Erro no upload: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Upload error: $e');
      }
      _showError('Erro ao fazer upload da imagem');
    }
  }

  void _removeImage(int index) async {
    if (kDebugMode) {
      print('Removing image at index: $index');
      print('Image before removal: ${_imagePaths[index]}');
      print('All images before: $_imagePaths');
    }
    
    // For existing ads, we need to determine if this is an existing image
    // For now, we'll just remove from the list and let PUT handle the update
    // In a more robust implementation, we would track image IDs and call DELETE /ad_images/{id}
    
    setState(() {
      _imagePaths.removeAt(index);
    });
    
    if (kDebugMode) {
      print('All images after: $_imagePaths');
    }
    
    _showError('Imagem removida com sucesso');
  }

  Future<void> _updateAd() async {
    if (kDebugMode) {
      print('=== UPDATE AD START ===');
      print('Form valid: ${_formKey.currentState?.validate()}');
      print('Selected Main Category: $_selectedMainCategoryId');
      print('Selected Subcategory: $_selectedSubcategoryId');
      print('Title: ${_titleController.text}');
      print('Description length: ${_descriptionController.text.length}');
      print('Price: ${_priceController.text}');
    }
    
    if (!_formKey.currentState!.validate()) {
      if (kDebugMode) {
        print('Form validation failed');
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });
    
    if (kDebugMode) {
      print('Form validation passed, proceeding with update');
    }

    try {
      // Validate required fields
      if (_selectedSubcategoryId == null || _selectedSubcategoryId!.isEmpty) {
        _showError('Por favor, selecione uma subcategoria');
        return;
      }
      
      // Parse price from formatted currency (handle optional price)
      double price = 0.0;
      String priceText = _priceController.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (priceText.isNotEmpty) {
        price = double.parse(priceText) / 100; // Convert from cents
      }
      
      // Prepare data with null checks
      final adData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': price,
        'negotiable': _negotiable ? 1 : 0,
        'condition_type': _selectedCondition ?? '',
        'category_id': int.parse(_selectedSubcategoryId!),
        'cep': _cep ?? '',
        'address': _address ?? '',
        'neighborhood': _neighborhood ?? '',
        'city': _selectedCity ?? '',
        'state': _selectedState ?? '',
        'phone': _phoneController.text.trim(),
        'show_phone': 1,
        'images': _imagePaths,
      };
      
      if (kDebugMode) {
        print('Images being sent: ${_imagePaths.length}');
        for (int i = 0; i < _imagePaths.length; i++) {
          print('Image $i: ${_imagePaths[i]}');
        }
      }
      
      // Remove null values from data
      adData.removeWhere((key, value) => value == null);
      
      if (kDebugMode) {
        print('=== CLEANED AD DATA ===');
        print('Final data: $adData');
        print('Data keys: ${adData.keys.toList()}');
      }

      if (kDebugMode) {
        print('=== SENDING AD UPDATE ===');
        print('URL: ${ApiConfig.ads}/${widget.ad!.id}');
        print('Data: $adData');
        print('Selected Main Category: $_selectedMainCategoryId');
        print('Selected Subcategory: $_selectedSubcategoryId');
      }
      
      final response = await ApiService.put('${ApiConfig.ads}/${widget.ad!.id}', adData);
      
      if (kDebugMode) {
        print('=== AD UPDATE RESPONSE ===');
        print('Response: $response');
        print('Success: ${response['success']}');
        if (response.containsKey('error')) {
          print('Error: ${response['error']}');
        }
        if (response.containsKey('message')) {
          print('Message: ${response['message']}');
        }
      }

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Anúncio atualizado com sucesso!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        } else {
          _showError(response['error'] ?? 'Erro ao atualizar anúncio');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('=== AD UPDATE ERROR ===');
        print('Error Type: ${e.runtimeType}');
        print('Error: $e');
        print('Stack Trace: $stackTrace');
        
        // Try to extract more details if it's an HTTP error
        if (e.toString().contains('400')) {
          print('HTTP 400 Bad Request - Invalid data');
        } else if (e.toString().contains('401')) {
          print('HTTP 401 Unauthorized - Authentication failed');
        } else if (e.toString().contains('404')) {
          print('HTTP 404 Not Found - Ad not found');
        } else if (e.toString().contains('500')) {
          print('HTTP 500 Internal Server Error');
        }
      }
      
      if (mounted) {
        _showError('Erro ao conectar com o servidor: ${e.toString()}');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.heroGradient,
          ),
        ),
        elevation: 0,
        title: const Text('Editar Anúncio'),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título do anúncio *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Campo obrigatório';
                        }
                        if (value.trim().length < 5) {
                          return 'Mínimo 5 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Descrição *',
                        border: OutlineInputBorder(),
                        hintText: 'Descreva seu produto ou serviço...',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Campo obrigatório';
                        }
                        if (value.trim().length < 10) {
                          return 'Mínimo 10 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Main Category
                    DropdownButtonFormField<String>(
                      value: _selectedMainCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Categoria Principal *',
                        border: OutlineInputBorder(),
                      ),
                      items: _mainCategories
                          .where((category) => category != null && category['id'] != null)
                          .map((category) {
                            return DropdownMenuItem(
                              value: category['id']?.toString(),
                              child: Text(
                                category['name'] ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            );
                          })
                          .toList(),
                      onChanged: _onMainCategoryChanged,
                      validator: (value) {
                        if (value == null) {
                          return 'Selecione uma categoria principal';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Subcategory
                    DropdownButtonFormField<String>(
                      value: _selectedSubcategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Subcategoria *',
                        border: OutlineInputBorder(),
                        hintText: 'Selecione primeiro a categoria principal',
                      ),
                      items: _filteredSubcategories
                          .map((category) {
                            return DropdownMenuItem(
                              value: category['id']?.toString(),
                              child: Text(
                                category['name'] ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            );
                          })
                          .toList(),
                      onChanged: _selectedMainCategoryId != null ? _onSubcategoryChanged : null,
                      validator: (value) {
                        if (value == null) {
                          return 'Selecione uma subcategoria';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Price and Negotiable
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Preço',
                              border: OutlineInputBorder(),
                              prefixText: 'R\$ ',
                              hintText: '0,00',
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              _CurrencyInputFormatter(),
                            ],
                            validator: (value) {
                              // Price is now optional
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CheckboxListTile(
                            title: const Text('Negociável'),
                            value: _negotiable,
                            onChanged: (value) {
                              setState(() {
                                _negotiable = value ?? false;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // CEP
                    TextFormField(
                      controller: _cepController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'CEP',
                        border: OutlineInputBorder(),
                        suffixIcon: _isSearchingCep
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.search),
                                onPressed: () => _searchCep(_cepController.text),
                              ),
                      ),
                      onChanged: (value) {
                        // Auto-search when CEP has 8 digits
                        if (value.length == 8 && !_isSearchingCep) {
                          _searchCep(value);
                        }
                      },
                    ),
                    
const SizedBox(height: 16),

                    // Estado
                    TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Estado',
                        border: const OutlineInputBorder(),
                        hintText: _selectedState ?? 'Será preenchido automaticamente',
                      ),
                      controller: TextEditingController(text: _selectedState ?? ''),
                    ),
                    const SizedBox(height: 16),

                    // Cidade
                    TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Cidade',
                        border: const OutlineInputBorder(),
                        hintText: _selectedCity ?? 'Será preenchido automaticamente',
                      ),
                      controller: TextEditingController(text: _selectedCity ?? ''),
                    ),
                    const SizedBox(height: 16),

                    // Bairro
                    TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Bairro',
                        border: const OutlineInputBorder(),
                        hintText: _neighborhood ?? 'Será preenchido automaticamente',
                      ),
                      controller: TextEditingController(text: _neighborhood ?? ''),
                    ),
                    const SizedBox(height: 16),

                    // Endereço/Logradouro
                    if (_address != null && _address!.isNotEmpty)
                      Column(
                        children: [
                          TextFormField(
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Endereço',
                              border: OutlineInputBorder(),
                            ),
                            controller: TextEditingController(text: _address ?? ''),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),

                    // Condition
                    DropdownButtonFormField<String>(
                      value: _selectedCondition,
                      decoration: const InputDecoration(
                        labelText: 'Condição',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Selecione')),
                        DropdownMenuItem(value: 'new', child: Text('Novo')),
                        DropdownMenuItem(value: 'used', child: Text('Usado')),
                        DropdownMenuItem(value: 'not_applicable', child: Text('Não aplicável')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCondition = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Telefone *',
                        border: OutlineInputBorder(),
                        prefixText: '+55 ',
                        hintText: '(11) 00000-0000',
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _PhoneInputFormatter(),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Campo obrigatório';
                        }
                        // Remove all non-digit characters for validation
                        String cleanPhone = value.replaceAll(RegExp(r'[^0-9]'), '');
                        if (cleanPhone.length < 10) {
                          return 'Telefone inválido (mínimo 10 dígitos)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Image Gallery
                    _buildImageGallery(),
                    
                    const SizedBox(height: 32),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (kDebugMode) {
                            print('=== SAVE BUTTON CLICKED ===');
                          }
                          _updateAd();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Atualizar Anúncio',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// Phone formatter for Brazilian phone numbers
class _CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: '',
    decimalDigits: 2,
  );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Get only digits
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Convert to double (divide by 100 to get decimal value)
    double value = double.parse(digitsOnly) / 100;
    
    // Format using NumberFormat
    String formatted = _formatter.format(value);
    
    // Remove any extra spaces
    formatted = formatted.trim();

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    
    // Remove all non-digit characters
    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleanText.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    // Limit to 11 digits (Brazilian phone max)
    if (cleanText.length > 11) {
      cleanText = cleanText.substring(0, 11);
    }
    
    String formattedText = '';
    
    if (cleanText.length <= 2) {
      // Just DDD
      formattedText = '($cleanText';
    } else if (cleanText.length <= 6) {
      // DDD + first digits
      formattedText = '(${cleanText.substring(0, 2)}) ${cleanText.substring(2)}';
    } else if (cleanText.length <= 10) {
      // Landline: (XX) XXXX-XXXX
      formattedText = '(${cleanText.substring(0, 2)}) ${cleanText.substring(2, 6)}-${cleanText.substring(6)}';
    } else {
      // Mobile: (XX) XXXXX-XXXX
      formattedText = '(${cleanText.substring(0, 2)}) ${cleanText.substring(2, 7)}-${cleanText.substring(7)}';
    }
    
    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

