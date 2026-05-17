import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/city.dart';
import '../models/place.dart';
import '../providers/auth_provider.dart';
import '../providers/cities_provider.dart';
import '../providers/places_provider.dart';
import '../theme/app_colors.dart';
import 'auth_screen.dart';

class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({super.key});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _mapController = MapController();
  String _selectedCategory = 'Cafe';
  int _priceRange = 1;
  Uint8List? _pickedImageBytes;
  LatLng? _selectedLocation;
  bool _hasPickedLocation = false;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Cafe',
    'Restaurant',
    'Market',
    'Shop',
    'Art & Culture',
    'Nightlife',
    'Outdoor',
    'Historical',
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _pickedImageBytes = bytes;
      });
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
      _hasPickedLocation = true;
    });
    _mapController.move(point, 15);
  }

  Future<void> _submitPlace() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasPickedLocation || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick the place location on the map.')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final placesProvider = Provider.of<PlacesProvider>(context, listen: false);
    final citiesProvider = Provider.of<CitiesProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (ctx) => AuthScreen()),
      );
      return;
    }

    final cityName = _cityController.text.trim();
    final country = _countryController.text.trim();

    setState(() => _isSubmitting = true);

    try {
      final city = citiesProvider.cityByName(cityName);
      if (city == null) {
        await citiesProvider.saveCity(
          City(
            name: cityName,
            country: country,
            placeCount: 1,
            latitude: _selectedLocation!.latitude,
            longitude: _selectedLocation!.longitude,
          ),
        );
      } else {
        await citiesProvider.incrementCityPlaceCount(cityName);
      }

      final newPlace = Place(
        id: '',
        title: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        price: _priceRange,
        rating: 0,
        hiddenGemScore: 0,
        image: '',
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        cityName: cityName,
        contributorId: authProvider.currentUser!.id,
        contributorName: authProvider.currentUser!.name,
        isApproved: authProvider.isApprovedLocal,
      );

      await placesProvider.addPlace(newPlace);
      await authProvider.incrementSharedPlaces();
      await authProvider.addPoints(10);
      await placesProvider.refreshContributedPlaces(authProvider.currentUser!.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.isApprovedLocal
                ? 'Place published! +10 points'
                : 'Place submitted for approval! +10 points',
          ),
          backgroundColor: AppColors.accent,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting place. Please try again.'),
          backgroundColor: AppColors.destructive,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Add Place'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 64, color: AppColors.muted),
                SizedBox(height: 24),
                Text(
                  'Sign in to add places',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Share your favorite hidden gems with the community',
                  style: TextStyle(fontSize: 14, color: AppColors.muted),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (ctx) => AuthScreen()),
                      );
                    },
                    child: Text('Sign In'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Add Place'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.border,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _pickedImageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            _pickedImageBytes!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (ctx, err, stack) =>
                                _buildUploadPlaceholder(),
                          ),
                        )
                      : _buildUploadPlaceholder(),
                ),
              ),
              SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Place Name',
                  hintText: 'Enter the name of the place',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a place name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Tell us about this hidden gem...',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'City',
                  hintText: 'Enter the city name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a city';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _countryController,
                decoration: InputDecoration(
                  labelText: 'Country',
                  hintText: 'Enter the country',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a country';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              Text(
                'Pick the exact location on the map',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.foreground,
                ),
              ),
              SizedBox(height: 8),
              Container(
                height: 280,
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLocation ??
                        const LatLng(30.0444, 31.2357),
                    initialZoom: 12,
                    onTap: _onMapTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.likealocal.app',
                    ),
                    if (_selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLocation!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Text(
                _hasPickedLocation
                    ? 'Location selected: ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}'
                    : 'Tap the map to mark the place location',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(labelText: 'Category'),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              SizedBox(height: 16),

              Text(
                'Price Range',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.foreground,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: List.generate(3, (index) {
                  final price = index + 1;
                  final isSelected = _priceRange == price;
                  return Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => setState(() => _priceRange = price),
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          '\$' * price,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppColors.foreground,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: 32),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPlace,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Submit Place (+10 points)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Your place will be reviewed by an admin before appearing in the app.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.camera_alt, size: 40, color: AppColors.muted),
        SizedBox(height: 8),
        Text(
          'Tap to add photo',
          style: TextStyle(fontSize: 14, color: AppColors.muted),
        ),
      ],
    );
  }
}
