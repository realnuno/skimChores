// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:new_uber/common/controller/services/toast_services.dart';
import 'package:new_uber/constant/constants.dart';
import 'package:uuid/uuid.dart';

class ImageServices {
  /// Pick image from gallery
  static Future<File?> getImageFromGallery({
    required BuildContext context,
  }) async {
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (pickedFile != null) {
        final image = File(pickedFile.path);
        log('Selected image path: ${image.path}');
        return image;
      } else {
        ToastServices.sendScaffoldAlert(
          msg: 'No Image Selected',
          toastStatus: 'ERROR',
          context: context,
        );
        return null;
      }
    } catch (e) {
      log('Image picking error: $e');
      ToastServices.sendScaffoldAlert(
        msg: 'Failed to pick image',
        toastStatus: 'ERROR',
        context: context,
      );
      return null;
    }
  }

  /// Upload image to Firebase Storage
  static Future<String?> uploadImageToFirebaseStorage({
    required File image,
    required BuildContext context,
  }) async {
    try {
      if (auth.currentUser == null) {
        throw Exception("User is not authenticated");
      }

      final String userID = auth.currentUser!.phoneNumber!;
      final String imageName = '$userID-${const Uuid().v1()}';
      final Reference ref = storage.ref().child('Profile_Images').child(imageName);

      final uploadTask = await ref.putFile(image);
      final imageUrl = await uploadTask.ref.getDownloadURL();

      log('Uploaded image URL: $imageUrl');
      return imageUrl;
    } catch (e, st) {
      log('Upload error: $e\n$st');
      ToastServices.sendScaffoldAlert(
        msg: 'Failed to upload image',
        toastStatus: 'ERROR',
        context: context,
      );
      return null;
    }
  }
}
