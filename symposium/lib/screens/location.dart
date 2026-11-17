import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/onboarding_data.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key,required this.data});final OnboardingData data;
  @override State<LocationPermissionScreen> createState()=>_LocationPermissionScreenState();
}
class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool loading=false;
  Future<void> finish() async {final prefs=await SharedPreferences.getInstance();await prefs.setBool('onboarding_complete',true);if(mounted)Navigator.pushNamedAndRemoveUntil(context,Routes.home,(_)=>false);}
  Future<void> locate() async {
    setState(()=>loading=true);
    try {
      if(!await Geolocator.isLocationServiceEnabled()){throw Exception('Location services are disabled.');}
      var permission=await Geolocator.checkPermission();
      if(permission==LocationPermission.denied)permission=await Geolocator.requestPermission();
      if(permission==LocationPermission.denied||permission==LocationPermission.deniedForever){throw Exception('Location permission is unavailable. Choose your city manually.');}
      final position=await Geolocator.getCurrentPosition(locationSettings:const LocationSettings(accuracy:LocationAccuracy.medium,timeLimit:Duration(seconds:12)));
      widget.data.latitude=position.latitude;widget.data.longitude=position.longitude;widget.data.locationGranted=true;
      try {final places=await placemarkFromCoordinates(position.latitude,position.longitude);if(places.isNotEmpty)widget.data.currentCity=places.first.locality??places.first.administrativeArea??'';}catch(_){widget.data.currentCity=widget.data.homeCity;}
      if(mounted)await finish();
    } catch(e){if(mounted)showDialog<void>(context:context,builder:(c)=>AlertDialog(title:const Text('Location unavailable'),content:Text('$e'),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('OK')),TextButton(onPressed:(){Navigator.pop(c);manual();},child:const Text('Choose city'))]));}
    finally{if(mounted)setState(()=>loading=false);}
  }
  Future<void> manual() async {final controller=TextEditingController(text:widget.data.homeCity);final city=await showDialog<String>(context:context,builder:(c)=>AlertDialog(title:const Text('Choose current city'),content:TextField(controller:controller,autofocus:true,decoration:const InputDecoration(hintText:'Enter city name')),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Cancel')),TextButton(onPressed:()=>Navigator.pop(c,controller.text.trim()),child:const Text('Continue'))]));controller.dispose();if(city!=null&&city.isNotEmpty){widget.data.currentCity=city;await finish();}}
  @override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:Padding(padding:const EdgeInsets.symmetric(horizontal:AppSpace.page),child:Column(children:[
    const SizedBox(height:29),const Align(alignment:Alignment.centerLeft,child:Text('SYMPOSIUM',style:TextStyle(fontSize:14,fontWeight:FontWeight.w700,color:AppColors.primary,letterSpacing:1.5))),
    const Spacer(),Container(width:230,height:230,decoration:BoxDecoration(color:AppColors.primaryLight,borderRadius:BorderRadius.circular(34)),child:const Icon(Icons.location_searching_rounded,color:AppColors.primary,size:105)),
    const SizedBox(height:38),Text('Find your people nearby',style:Theme.of(context).textTheme.headlineLarge,textAlign:TextAlign.center),
    const SizedBox(height:19),const Text('Allow location access to discover people and shared interests around you. Your exact location stays private.',textAlign:TextAlign.center,style:TextStyle(color:AppColors.secondary,height:1.5)),
    const Spacer(),PrimaryButton(label:'Use Current Location',loading:loading,onPressed:locate),
    const SizedBox(height:9),TextAction(label:'Choose location manually',onPressed:manual),const SizedBox(height:24),
  ]))));
}

class HomePreviewScreen extends StatelessWidget {
  const HomePreviewScreen({super.key,required this.data});final OnboardingData data;
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('SYMPOSIUM',style:TextStyle(color:AppColors.primary,fontWeight:FontWeight.w700,letterSpacing:1.2))),body:SafeArea(child:Padding(padding:const EdgeInsets.all(AppSpace.page),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text('Welcome, ${data.name.isEmpty?'Neighbour':data.name}!',style:Theme.of(context).textTheme.headlineMedium),const SizedBox(height:14),
    Text('⌖  ${data.currentCity.isEmpty?data.homeCity:data.currentCity} · Change',style:const TextStyle(color:AppColors.primary,fontWeight:FontWeight.w600)),const SizedBox(height:22),
    const Text('Your onboarding is complete.',style:TextStyle(color:AppColors.secondary)),const SizedBox(height:10),
    const Text('This is a navigation handoff placeholder. Connect the full KYN Home screen in the next implementation phase.',style:TextStyle(color:AppColors.secondary)),
  ]))));
}
