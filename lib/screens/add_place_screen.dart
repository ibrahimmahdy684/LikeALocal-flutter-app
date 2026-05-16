import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/places_provider.dart';
import '../models/place.dart';
import 'auth_screen.dart';

class AddPlaceScreen extends StatefulWidget {
  @override
  _AddPlaceScreenState createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Cafe';
  int _priceRange = 1;
  XFile? _pickedImage;
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
      setState(() => _pickedImage = image);
    }
  }

  Future<void> _submitPlace() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final placesProvider =
        Provider.of<PlacesProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (ctx) => AuthScreen()),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      Place newPlace = Place(
        id: '',
        title: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        price: _priceRange,
        rating: 0,
        hiddenGemScore: 0,
        image: '', // Would upload to Firebase Storage in production
        cityName: 'Paris', // Default or user-selected city
        contributorId: authProvider.currentUser!.id,
        contributorName: authProvider.currentUser!.name,
        isApproved: authProvider.isLocal,
      );

      await placesProvider.addPlace(newPlace);
      await authProvider.incrementSharedPlaces();
      await authProvider.addPoints(10);
      await placesProvider.refreshContributedPlaces(authProvider.currentUser!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.isLocal
                  ? 'Place published! +10 points'
                  : 'Place submitted for approval! +10 points',
            ),
            backgroundColor: AppColors.accent,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Guest state - show lock screen
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
              // Image upload
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
                  child: _pickedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            _pickedImage!.path,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (ctx, err, stack) => _buildUploadPlaceholder(),
                          ),
                        )
                      : _buildUploadPlaceholder(),
                ),
              ),
              SizedBox(height: 24),

              // Place name
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

              // Description
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

              // Category dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(labelText: 'Category'),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              SizedBox(height: 16),

              // Price range
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
                  int price = index + 1;
                  bool isSelected = _priceRange == price;
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

              // Submit button
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
