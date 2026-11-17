import 'package:flutter/material.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../core/onboarding_data.dart';
import '../widgets/common.dart';

class BasicProfileScreen extends StatefulWidget {
  const BasicProfileScreen({super.key, required this.data});
  final OnboardingData data;
  @override State<BasicProfileScreen> createState() => _BasicProfileScreenState();
}
class _BasicProfileScreenState extends State<BasicProfileScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final dob = TextEditingController();
  String? gender;
  @override void dispose() {name.dispose();dob.dispose();super.dispose();}
  @override Widget build(BuildContext context) => Form(key: form, child: OnboardingShell(step: 1, title: 'Profile basics', subtitle: "Let's get to know you. Create your profile to help neighbours recognise you.", children: [
    Center(child: Column(children: [CircleAvatar(radius: 45, backgroundColor: AppColors.primaryLight, child: Icon(Icons.add_a_photo_outlined, size: 35, color: AppColors.primary)), const SizedBox(height: 8), const Text('Add profile photo', style: TextStyle(color: AppColors.primary, fontSize: 13))])),
    FormFieldGroup(label: 'Full name', controller: name, hint: 'Enter your full name', validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required' : null),
    FormFieldGroup(label: 'Date of birth', controller: dob, hint: 'Select date of birth', readOnly: true, onTap: () async { final d = await showDatePicker(context: context, initialDate: DateTime(2000), firstDate: DateTime(1940), lastDate: DateTime.now()); if(d != null) {widget.data.dob=d;dob.text='${d.day}/${d.month}/${d.year}';}}),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Gender (optional)', style: TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 8), DropdownButtonFormField<String>(value: gender, hint: const Text('Select gender'), items: ['Male','Female','Non-binary','Prefer not to say'].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(), onChanged:(v)=>setState(()=>gender=v))]),
  ], buttonLabel: 'Continue', onNext: () {if(form.currentState!.validate()) {widget.data.name=name.text.trim();widget.data.gender=gender??'';Navigator.pushNamed(context, Routes.professional);}}));
}

class ProfessionalProfileScreen extends StatefulWidget {
  const ProfessionalProfileScreen({super.key, required this.data});
  final OnboardingData data;
  @override State<ProfessionalProfileScreen> createState()=>_ProfessionalProfileScreenState();
}
class _ProfessionalProfileScreenState extends State<ProfessionalProfileScreen> {
  final form=GlobalKey<FormState>();
  final job=TextEditingController(),industry=TextEditingController(),company=TextEditingController(),experience=TextEditingController(),skills=TextEditingController();
  @override void dispose(){for(final c in [job,industry,company,experience,skills]){c.dispose();}super.dispose();}
  @override Widget build(BuildContext context)=>Form(key:form,child:OnboardingShell(step:2,title:'What do you do?',subtitle:'Complete your professional profile to unlock better matches. Find people with similar backgrounds and experiences.',children:[
    FormFieldGroup(label:'Job title / Profession',controller:job,hint:'e.g. Software Engineer',validator:(v)=>v==null||v.trim().isEmpty?'Enter your profession':null),
    FormFieldGroup(label:'Industry',controller:industry,hint:'e.g. Technology'),
    FormFieldGroup(label:'Company / Organisation',controller:company,hint:'Where do you work?'),
    FormFieldGroup(label:'Years of experience',controller:experience,hint:'e.g. 5 years'),
    FormFieldGroup(label:'Skills',controller:skills,hint:'e.g. Flutter, Design, Marketing'),
  ],buttonLabel:'Continue',onNext:(){if(form.currentState!.validate()){widget.data.profession=job.text;widget.data.industry=industry.text;widget.data.company=company.text;widget.data.experience=experience.text;widget.data.skills=skills.text;Navigator.pushNamed(context,Routes.interests);}}));
}

class InterestsScreen extends StatefulWidget {
  const InterestsScreen({super.key,required this.data});final OnboardingData data;
  @override State<InterestsScreen> createState()=>_InterestsScreenState();
}
class _InterestsScreenState extends State<InterestsScreen> {
  static const options=['Technology','Business','Fitness','Coffee','Travel','Startups','Design','Music','Food','Books','Sports','Photography','Networking','Art','Community','Wellness','Entrepreneurship','Movies'];
  @override Widget build(BuildContext context)=>OnboardingShell(step:3,title:'What are you into?',subtitle:"Choose the interests you'd love to share with others. Pick at least three.",children:[
    ChoiceChips(options:options,selected:widget.data.interests,onToggle:(v)=>setState((){widget.data.interests.contains(v)?widget.data.interests.remove(v):widget.data.interests.add(v);})),
    Text('${widget.data.interests.length} interests selected',style:const TextStyle(color:AppColors.secondary,fontSize:13)),
  ],buttonLabel:'Continue',onNext:(){if(widget.data.interests.length<3){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Please select at least 3 interests')));return;}Navigator.pushNamed(context,Routes.location);});
}

class ConnectionLocationScreen extends StatefulWidget {
  const ConnectionLocationScreen({super.key,required this.data});final OnboardingData data;
  @override State<ConnectionLocationScreen> createState()=>_ConnectionLocationScreenState();
}
class _ConnectionLocationScreenState extends State<ConnectionLocationScreen> {
  final form=GlobalKey<FormState>();final city=TextEditingController(),locality=TextEditingController();String? goal,meeting;
  @override void dispose(){city.dispose();locality.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Form(key:form,child:OnboardingShell(step:4,title:'Your neighbourhood, your people',subtitle:"Tell us where and how you'd like to connect.",children:[
    FormFieldGroup(label:'Home city',controller:city,hint:'e.g. Ahmedabad',validator:(v)=>v==null||v.trim().isEmpty?'Select your home city':null),
    FormFieldGroup(label:'Home locality (optional)',controller:locality,hint:'e.g. South Bopal'),
    const Text('What brings you here?',style:TextStyle(fontWeight:FontWeight.w600)),
    DropdownButtonFormField<String>(value:goal,hint:const Text('Select your goal'),items:['Make friends','Professional networking','Find local community','Explore nearby people'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>setState(()=>goal=v)),
    const Text('Meeting preference',style:TextStyle(fontWeight:FontWeight.w600)),
    DropdownButtonFormField<String>(value:meeting,hint:const Text('Select preference'),items:['Chat first','Coffee / Public meetup','Online only','Open to both'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>setState(()=>meeting=v)),
    const Text('Your exact GPS coordinates will never be shown on your public profile.',style:TextStyle(color:AppColors.secondary,fontSize:12)),
  ],buttonLabel:'Continue',onNext:(){if(form.currentState!.validate()){widget.data.homeCity=city.text.trim();widget.data.locality=locality.text.trim();widget.data.connectionGoal=goal??'';widget.data.meetingPreference=meeting??'';Navigator.pushNamed(context,Routes.permission);}}));
}
