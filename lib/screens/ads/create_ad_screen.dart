import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/storage_helper.dart';
import '../../utils/theme.dart';

class CreateAdScreen extends StatefulWidget {
  const CreateAdScreen({super.key});

  @override
  State<CreateAdScreen> createState() => _CreateAdScreenState();
}

class _CreateAdScreenState extends State<CreateAdScreen> {
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

  // Ad limit tracking
  Map<String, dynamic> _adLimitInfo = {
    'canCreate': true,
    'current': 0,
    'limit': 5,
    'remaining': 5,
  };

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _mainCategories = [];
  List<Map<String, dynamic>> _subcategories = [];
  String? _selectedMainCategoryId;
  String? _selectedSubcategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadCategories();
        _loadAdLimitInfo();
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

  Future<void> _loadAdLimitInfo() async {
    try {
      final limitCheck = await _checkAdLimit();
      if (mounted) {
        setState(() {
          _adLimitInfo = limitCheck;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading ad limit info: $e');
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
        print('Success: ${response['success']}');
        print('Categories: ${response['categories']}');
      }
      
      if (response['success'] == true && response['categories'] != null) {
        final List<Map<String, dynamic>> mainCategories = [];
        final List<Map<String, dynamic>> subcategories = [];
        
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
          print('Main Categories Found: ${mainCategories.length}');
          print('Subcategories Found: ${subcategories.length}');
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
      _selectedSubcategoryId = null;
    });
  }

  void _onSubcategoryChanged(String? value) {
    setState(() {
      _selectedSubcategoryId = value;
    });
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

  Future<void> _addImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      await _uploadImage(image);
    }
  }

  Future<void> _uploadImage(XFile image) async {
    try {
      if (kDebugMode) {
        print('=== UPLOAD DEBUG START ===');
        print('Image path: ${image.path}');
        print('Image name: ${image.name}');
        print('Image size: ${await image.length()} bytes');
        print('Upload endpoint: upload');
      }
      
      // Read image bytes directly
      final imageBytes = await image.readAsBytes();
      if (kDebugMode) {
        print('Image bytes read: ${imageBytes.length} bytes');
        print('Image type: ${image.mimeType ?? 'unknown'}');
      }
      
      // Use ApiService to handle the upload with bytes
      final response = await ApiService.postMultipartBytes(
        'upload',
        {'image': imageBytes, 'filename': image.name},
      );
      
      if (kDebugMode) {
        print('Upload response: $response');
      }
      
      if (response['success'] == true) {
        String imageUrl = response['url'];
        String relativePath = response['path'] ?? 'ads/temp/' + response['filename'];
        
        setState(() {
          _imagePaths.add(relativePath);
        });
        
        _showSuccess('Imagem adicionada com sucesso!');
      } else {
        _showError('Erro no upload: ${response['error']}');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('=== UPLOAD ERROR ===');
        print('Error: $e');
        print('Stack trace: $stackTrace');
      }
      _showError('Erro ao fazer upload da imagem: ${e.toString()}');
    }
  }

  Future<void> _createAd() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final auth = context.read<AuthProvider>();
      if (!auth.isAuthenticated) {
        _showError('Usuário não autenticado');
        return;
      }

      // Check ad limit before creating
      final limitCheck = await _checkAdLimit();
      if (!limitCheck['canCreate']) {
        _showError(limitCheck['message']);
        return;
      }

      final adData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': _priceController.text.trim().isEmpty ? null : _priceController.text.replaceAll(',', '.'),
        'negotiable': _negotiable ? 1 : 0,
        'category_id': _selectedSubcategoryId ?? _selectedMainCategoryId,
        'condition': _selectedCondition,
        'cep': _cepController.text,
        'state': _selectedState,
        'city': _selectedCity,
        'neighborhood': _neighborhood,
        'address': _address,
        'phone': _phoneController.text,
        'images': _imagePaths,
      };

      final response = await ApiService.post(ApiConfig.ads, adData);
      
      if (mounted) {
        if (response['success'] == true) {
          _showSuccess('Anúncio criado com sucesso!');
          Navigator.of(context).pop(true);
        } else {
          _showError(response['error'] ?? 'Erro ao criar anúncio');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Erro ao conectar com o servidor: ${e.toString()}');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _checkAdLimit() async {
    try {
      // Check user's ad package and usage using the backend system
      final response = await ApiService.get(ApiConfig.userPackage);
      
      if (response['success'] == true) {
        final packageInfo = response['package'] ?? {};
        final usageInfo = response['usage'] ?? {};
        
        final current = usageInfo['used'] ?? 0;
        final limit = usageInfo['limit'] ?? 5; // Default to 5 if not set
        final remaining = usageInfo['remaining'] ?? (limit - current);
        
        if (kDebugMode) {
          print('Ad limit check: $current/$limit used, $remaining remaining');
          print('Package info: $packageInfo');
        }
        
        if (remaining <= 0) {
          return {
            'canCreate': false,
            'message': 'Você atingiu seu limite de $limit anúncios. Para criar mais anúncios, faça upgrade do seu plano.',
            'current': current,
            'limit': limit,
            'remaining': 0
          };
        }
        
        return {
          'canCreate': true,
          'message': 'Você pode criar mais $remaining anúncios',
          'current': current,
          'limit': limit,
          'remaining': remaining
        };
      } else {
        // If package endpoint fails, fallback to checking ads directly
        final adsResponse = await ApiService.get('ads?user_id=me');
        
        if (adsResponse['success'] == true && adsResponse['ads'] != null) {
          final currentAds = adsResponse['ads'] as List;
          final activeAds = currentAds.where((ad) => 
            ad['status'] == 'active' || ad['status'] == 'pending'
          ).length;
          
          // Default free limit
          const freeLimit = 5;
          final remaining = freeLimit - activeAds;
          
          if (kDebugMode) {
            print('Fallback ad limit check: $activeAds/$freeLimit used, $remaining remaining');
          }
          
          if (remaining <= 0) {
            return {
              'canCreate': false,
              'message': 'Você atingiu seu limite de $freeLimit anúncios. Para criar mais anúncios, faça upgrade do seu plano.',
              'current': activeAds,
              'limit': freeLimit,
              'remaining': 0
            };
          }
          
          return {
            'canCreate': true,
            'message': 'Você pode criar mais $remaining anúncios',
            'current': activeAds,
            'limit': freeLimit,
            'remaining': remaining
          };
        } else {
          // If we can't check, allow creation but log the error
          if (kDebugMode) {
            print('Could not verify ad limit, allowing creation');
          }
          return {
            'canCreate': true,
            'message': 'Limite não verificado, permitindo criação',
          };
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking ad limit: $e');
      }
      // If there's an error, allow creation
      return {
        'canCreate': true,
        'message': 'Erro ao verificar limite, permitindo criação',
      };
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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Widget _buildImageGallery() {
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
                  image: DecorationImage(
                    image: NetworkImage(
                      _imagePaths[index].startsWith('ads/temp/') 
                        ? '${ApiConfig.imageProxyUrl}?path=${_imagePaths[index]}'
                        : 'https://localviva.com.br/uploads/${_imagePaths[index]}'
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _imagePaths.removeAt(index);
                          });
                        },
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
              );
            },
          ),
        ),
      ],
    );
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
        title: const Text('Criar Anúncio'),
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
                        border: const OutlineInputBorder(),
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
                    const SizedBox(height: 24),

                    // Image Gallery
                    _buildImageGallery(),
                    const SizedBox(height: 24),

                    // Ad Limit Indicator
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _adLimitInfo['canCreate'] ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _adLimitInfo['canCreate'] ? Colors.green.shade200 : Colors.red.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _adLimitInfo['canCreate'] ? Icons.check_circle : Icons.warning,
                            color: _adLimitInfo['canCreate'] ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _adLimitInfo['canCreate'] 
                                ? 'Você pode criar ${_adLimitInfo['remaining']} anúncio(s)'
                                : 'Limite atingido: ${_adLimitInfo['current']}/${_adLimitInfo['limit']} anúncios',
                              style: TextStyle(
                                color: _adLimitInfo['canCreate'] ? Colors.green.shade800 : Colors.red.shade800,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (_isLoading || !_adLimitInfo['canCreate']) ? null : _createAd,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _adLimitInfo['canCreate'] ? AppColors.primary : Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                _adLimitInfo['canCreate'] ? 'Criar Anúncio' : 'Limite Atingido',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
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
