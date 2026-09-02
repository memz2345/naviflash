// lib/screens/open_source_licenses_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naviflash/widgets/app_toast.dart';
import '../widgets/expressive_app_bar.dart';
import '../widgets/morph_card.dart';
import '../widgets/page_background.dart';
import '../l10n/app_localizations.dart';


/// 单个引用的开源项目
class LicenseEntry {
  final String package;
  final String version;
  final String license;
  const LicenseEntry({
    required this.package,
    required this.version,
    required this.license,
  });
}

/// 按许可证分组
class LicenseGroup {
  final String name;
  final List<LicenseEntry> entries;
  const LicenseGroup({required this.name, required this.entries});
}


const List<LicenseGroup> _groups = [
  LicenseGroup(
    name: 'MIT License',
    entries: [
      LicenseEntry(package: 'media_kit', version: '^1.0.25', license: 'MIT'),
      LicenseEntry(
        package: 'media_kit_video',
        version: '^1.1.8',
        license: 'MIT',
      ),
      LicenseEntry(
        package: 'media_kit_libs_video',
        version: '^1.0.6',
        license: 'MIT',
      ),
      LicenseEntry(package: 'provider', version: '^6.1.5+1', license: 'MIT'),
      LicenseEntry(package: 'image', version: '^4.1.3', license: 'MIT'),
      LicenseEntry(package: 'file_picker', version: '^10.3.10', license: 'MIT'),
      LicenseEntry(
        package: 'permission_handler',
        version: '^11.0.1',
        license: 'MIT',
      ),
      LicenseEntry(package: 'flutter_svg', version: '^2.3.0', license: 'MIT'),
      LicenseEntry(package: 'xml', version: '^6.5.0', license: 'MIT'),
      LicenseEntry(
        package: 'cupertino_icons',
        version: '^1.0.8',
        license: 'MIT',
      ),
      LicenseEntry(
        package: 'emoji_picker_flutter',
        version: '^2.1.0',
        license: 'MIT',
      ),
      LicenseEntry(
        package: 'flutter_colorpicker',
        version: '^1.1.0',
        license: 'MIT',
      ),
      LicenseEntry(package: 'gal', version: '^2.3.0', license: 'MIT'),
      LicenseEntry(package: 'screenshot', version: '^3.0.0', license: 'MIT'),
      LicenseEntry(
        package: 'mobile_scanner',
        version: '^5.2.3',
        license: 'MIT',
      ),
      LicenseEntry(
        package: 'flutter_displaymode',
        version: '^0.7.0',
        license: 'MIT',
      ),
      LicenseEntry(
        package: 'video_thumbnail',
        version: '^0.5.3',
        license: 'MIT',
      ),
      LicenseEntry(package: 'desktop_drop', version: '^0.4.4', license: 'MIT'),
      LicenseEntry(package: 'open_file', version: '^3.5.4', license: 'MIT'),
      LicenseEntry(
        package: 'awesome_notifications',
        version: '^0.11.0',
        license: 'MIT',
      ),
      LicenseEntry(
        package: 'flutter_foreground_task',
        version: '^8.0.0',
        license: 'MIT',
      ),
      LicenseEntry(
        package: 'webview_windows',
        version: '^0.4.0',
        license: 'MIT',
      ),
    ],
  ),
  LicenseGroup(
    name: 'Apache License 2.0',
    entries: [
      LicenseEntry(package: 'hive', version: '^2.2.3', license: 'Apache-2.0'),
      LicenseEntry(
        package: 'hive_ce',
        version: '^2.19.3',
        license: 'Apache-2.0',
      ),
    ],
  ),
  LicenseGroup(
    name: 'BSD 3-Clause License',
    entries: [
      LicenseEntry(
        package: 'shared_preferences',
        version: '^2.2.2',
        license: 'BSD-3-Clause',
      ),
      LicenseEntry(
        package: 'path_provider',
        version: '^2.1.1',
        license: 'BSD-3-Clause',
      ),
      LicenseEntry(package: 'http', version: '^1.1.0', license: 'BSD-3-Clause'),
      LicenseEntry(package: 'intl', version: 'any', license: 'BSD-3-Clause'),
      LicenseEntry(package: 'mime', version: '^1.0.5', license: 'BSD-3-Clause'),
      LicenseEntry(
        package: 'url_launcher',
        version: '^6.3.2',
        license: 'BSD-3-Clause',
      ),
      LicenseEntry(
        package: 'webview_flutter',
        version: '^4.13.1',
        license: 'BSD-3-Clause',
      ),
      LicenseEntry(
        package: 'image_picker',
        version: '^1.0.4',
        license: 'BSD-3-Clause',
      ),
      LicenseEntry(
        package: 'dynamic_color',
        version: '^1.6.8',
        license: 'BSD-3-Clause',
      ),
      LicenseEntry(
        package: 'flutter_local_notifications',
        version: '^17.0.0',
        license: 'BSD-3-Clause',
      ),
      LicenseEntry(
        package: 'flutter_secure_storage',
        version: '^10.3.1',
        license: 'BSD-3-Clause',
      ),
      LicenseEntry(
        package: 'share_plus',
        version: '^12.0.2',
        license: 'BSD-3-Clause',
      ),
      LicenseEntry(
        package: 'device_info_plus',
        version: '^12.4.0',
        license: 'BSD-3-Clause',
      ),
      LicenseEntry(
        package: 'battery_plus',
        version: '^6.0.0',
        license: 'BSD-3-Clause',
      ),
      LicenseEntry(
        package: 'connectivity_plus',
        version: '^6.0.0',
        license: 'BSD-3-Clause',
      ),
      LicenseEntry(
        package: 'flutter_webrtc',
        version: '^1.5.2',
        license: 'BSD-3-Clause',
      ),
      LicenseEntry(
        package: 'protobuf',
        version: '^6.0.0',
        license: 'BSD-3-Clause',
      ),
      LicenseEntry(
        package: 'crypto',
        version: '^3.0.3',
        license: 'BSD-3-Clause',
      ),
      LicenseEntry(
        package: 'window_manager',
        version: '^0.3.8',
        license: 'BSD-3-Clause',
      ),
      LicenseEntry(
        package: 'local_notifier',
        version: '^0.1.6',
        license: 'BSD-3-Clause',
      ),
      LicenseEntry(
        package: 'flutter_acrylic',
        version: '^1.1.4',
        license: 'BSD-3-Clause',
      ),
      LicenseEntry(
        package: 'bitsdojo_window',
        version: '^0.1.6',
        license: 'BSD-3-Clause',
      ),
      LicenseEntry(
        package: 'qr_flutter',
        version: '^4.1.0',
        license: 'BSD-3-Clause',
      ),
    ],
  ),
];


const String _mitText = '''
MIT License

Copyright (c) the respective copyright holders of each project

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
''';

const String _bsdText = '''
BSD 3-Clause License

Copyright (c) the respective copyright holders of each project
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
''';

const String _apacheText = '''
                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

   1. Definitions.

      "License" shall mean the terms and conditions for use, reproduction,
      and distribution as defined by Sections 1 through 9 of this document.

      "Licensor" shall mean the copyright owner or entity authorized by
      the copyright owner that is granting the License.

      "Legal Entity" shall mean the union of the acting entity and all
      other entities that control, are controlled by, or are under common
      control with that entity. For the purposes of this definition,
      "control" means (i) the power, direct or indirect, to cause the
      direction or management of such entity, whether by contract or
      otherwise, or (ii) ownership of fifty percent (50%) or more of the
      outstanding shares, or (iii) beneficial ownership of such entity.

      "You" (or "Your") shall mean an individual or Legal Entity
      exercising permissions granted by this License.

      "Source" form shall mean the preferred form for making modifications,
      including but not limited to software source code, documentation
      source, and configuration files.

      "Object" form shall mean any form resulting from mechanical
      transformation or translation of a Source form, including but
      not limited to compiled object code, generated documentation,
      and conversions to other media types.

      "Work" shall mean the work of authorship, whether in Source or
      Object form, made available under the License, as indicated by a
      copyright notice that is included in or attached to the work
      (an example is provided in the Appendix below).

      "Derivative Works" shall mean any work, whether in Source or Object
      form, that is based on (or derived from) the Work and for which the
      editorial revisions, annotations, elaborations, or other modifications
      represent, as a whole, an original work of authorship. For the purposes
      of this License, Derivative Works shall not include works that remain
      separable from, or merely link (or bind by name) to the interfaces of,
      the Work and Derivative Works thereof.

      "Contribution" shall mean any work of authorship, including
      the original version of the Work and any modifications or additions
      to that Work or Derivative Works thereof, that is intentionally
      submitted to Licensor for inclusion in the Work by the copyright owner
      or by an individual or Legal Entity authorized to submit on behalf of
      the copyright owner. For the purposes of this definition, "submitted"
      means any form of electronic, verbal, or written communication sent
      to the Licensor or its representatives, including but not limited to
      communication on electronic mailing lists, source code control systems,
      and issue tracking systems that are managed by, or on behalf of, the
      Licensor for the purpose of discussing and improving the Work, but
      excluding communication that is conspicuously marked or otherwise
      designated in writing by the copyright owner as "Not a Contribution."

      "Contributor" shall mean Licensor and any individual or Legal Entity
      on behalf of whom a Contribution has been received by Licensor and
      subsequently incorporated within the Work.

   2. Grant of Copyright License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      copyright license to reproduce, prepare Derivative Works of,
      publicly display, publicly perform, sublicense, and distribute the
      Work and such Derivative Works in Source or Object form.

   3. Grant of Patent License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      (except as stated in this section) patent license to make, have made,
      use, offer to sell, sell, import, and otherwise transfer the Work,
      where such license applies only to those patent claims licensable
      by such Contributor that are necessarily infringed by their
      Contribution(s) alone or by combination of their Contribution(s)
      with the Work to which such Contribution(s) was submitted. If You
      institute patent litigation against any entity (including a
      cross-claim or counterclaim in a lawsuit) alleging that the Work
      or a Contribution incorporated within the Work constitutes direct
      or contributory patent infringement, then any patent licenses
      granted to You under this License for that Work shall terminate
      as of the date such litigation is filed.

   4. Redistribution. You may reproduce and distribute copies of the
      Work or Derivative Works thereof in any medium, with or without
      modifications, and in Source or Object form, provided that You
      meet the following conditions:

      (a) You must give any other recipients of the Work or
          Derivative Works a copy of this License; and

      (b) You must cause any modified files to carry prominent notices
          stating that You changed the files; and

      (c) You must retain, in the Source form of any Derivative Works
          that You distribute, all copyright, patent, trademark, and
          attribution notices from the Source form of the Work,
          excluding those notices that do not pertain to any part of
          the Derivative Works; and

      (d) If the Work includes a "NOTICE" text file as part of its
          distribution, then any Derivative Works that You distribute must
          include a readable copy of the attribution notices contained
          within such NOTICE file, excluding those notices that do not
          pertain to any part of the Derivative Works, in at least one
          of the following places: within a NOTICE text file distributed
          as part of the Derivative Works; within the Source form or
          documentation, if provided along with the Derivative Works; or,
          within a display generated by the Derivative Works, if and
          wherever such third-party notices normally appear. The contents
          of the NOTICE file are for informational purposes only and
          do not modify the License. You may add Your own attribution
          notices within Derivative Works that You distribute, alongside
          or as an addendum to the NOTICE text from the Work, provided
          that such additional attribution notices cannot be construed
          as modifying the License.

      You may add Your own copyright statement to Your modifications and
      may provide additional or different license terms and conditions
      for use, reproduction, or distribution of Your modifications, or
      for any such Derivative Works as a whole, provided Your use,
      reproduction, and distribution of the Work otherwise complies with
      the conditions stated in this License.

   5. Submission of Contributions. Unless You explicitly state otherwise,
      any Contribution intentionally submitted for inclusion in the Work
      by You to the Licensor shall be under the terms and conditions of
      this License, without any additional terms or conditions.
      Notwithstanding the above, nothing herein shall supersede or modify
      the terms of any separate license agreement you may have executed
      with Licensor regarding such Contributions.

   6. Trademarks. This License does not grant permission to use the trade
      names, trademarks, service marks, or product names of the Licensor,
      except as required for reasonable and customary use in describing the
      origin of the Work and reproducing the content of the NOTICE file.

   7. Disclaimer of Warranty. Unless required by applicable law or
      agreed to in writing, Licensor provides the Work (and each
      Contributor provides its Contributions) on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
      implied, including, without limitation, any warranties or conditions
      of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
      PARTICULAR PURPOSE. You are solely responsible for determining the
      appropriateness of using or redistributing the Work and assume any
      risks associated with Your exercise of permissions under this License.

   8. Limitation of Liability. In no event and under no legal theory,
      whether in tort (including negligence), contract, or otherwise,
      unless required by applicable law (such as deliberate and grossly
      negligent acts) or agreed to in writing, shall any Contributor be
      liable to You for damages, including any direct, indirect, special,
      incidental, or consequential damages of any character arising as a
      result of this License or out of the use or inability to use the
      Work (including but not limited to damages for loss of goodwill,
      work stoppage, computer failure or malfunction, or any and all
      other commercial damages or losses), even if such Contributor
      has been advised of the possibility of such damages.

   9. Accepting Warranty or Additional Liability. While redistributing
      the Work or Derivative Works thereof, You may choose to offer,
      and charge a fee for, acceptance of support, warranty, indemnity,
      or other liability obligations and/or rights consistent with this
      License. However, in accepting such obligations, You may act only
      on Your own behalf and on Your sole responsibility, not on behalf
      of any other Contributor, and only if You agree to indemnify,
      defend, and hold each Contributor harmless for any liability
      incurred by, or claims asserted against, such Contributor by reason
      of your accepting any such warranty or additional liability.

   END OF TERMS AND CONDITIONS

   APPENDIX: How to apply the Apache License to your work.

      To apply the Apache License to your work, attach the following
      boilerplate notice, with the fields enclosed by brackets "[]"
      replaced with your own identifying information. (Don't include
      the brackets!)  The text should be enclosed in the appropriate
      comment syntax for the file format. We also recommend that a
      file or class name and description of purpose be included on the
      same "printed page" as the copyright notice for easier
      identification within third-party archives.

   Copyright [yyyy] [name of copyright owner]

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
''';

const Map<String, String> _licenseTexts = {
  'MIT': _mitText,
  'BSD-3-Clause': _bsdText,
  'Apache-2.0': _apacheText,
};


class OpenSourceLicensesPage extends StatefulWidget {
  final bool isSplitView;
  final VoidCallback? onBack;

  const OpenSourceLicensesPage({
    super.key,
    this.isSplitView = false,
    this.onBack,
  });

  @override
  State<OpenSourceLicensesPage> createState() => _OpenSourceLicensesPageState();
}

class _OpenSourceLicensesPageState extends State<OpenSourceLicensesPage> {
  int get _totalCount => _groups.fold(0, (sum, g) => sum + g.entries.length);

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _showLicenseSheet(String package, String version, String license) {
    final text = _licenseTexts[license] ?? '';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) => _LicenseSheet(
        package: package,
        version: version,
        license: license,
        text: text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      body: Stack(
        children: [
          PageBackground(baseColor: cs.surfaceContainer),
          CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              ExpressiveSliverAppBar(
                title: l10n.ossTitle,
                expandedHeight: 120,
                leading: widget.isSplitView
                    ? null
                    : MorphIconButton(
                        tooltip: l10n.ossBackTooltip,
                        icon: Icons.arrow_back,
                        onTap: _handleBack,
                      ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSummaryCard(cs),
                    const SizedBox(height: 32),
                    ..._groups.map((group) => _buildGroupSection(cs, group)),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 顶部总结卡片 ──

  Widget _buildSummaryCard(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    return MorphItem(
      selected: false,
      isFirst: true,
      isLast: true,
      interactive: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.code_rounded,
                size: 24,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.ossThanks,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.ossSummary(_totalCount),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 许可分组 ──

  Widget _buildGroupSection(ColorScheme cs, LicenseGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(
            context,
          ).ossGroupCount(group.name, group.entries.length),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 12),
        ...buildMorphSegmentedList(
          group.entries.map((entry) {
            return MorphRowItem(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: _LicenseBadge(
                  label: _licenseShortName(entry.license),
                  color: _licenseBadgeColor(cs, entry.license),
                ),
                title: Text(
                  entry.package,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  entry.version,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: cs.onSurfaceVariant,
                  size: 20,
                ),
                onTap: () => _showLicenseSheet(
                  entry.package,
                  entry.version,
                  entry.license,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  String _licenseShortName(String license) => switch (license) {
    'MIT' => 'MIT',
    'Apache-2.0' => 'Apache',
    'BSD-3-Clause' => 'BSD',
    _ => license,
  };

  Color _licenseBadgeColor(ColorScheme cs, String license) => switch (license) {
    'MIT' => cs.tertiaryContainer,
    'Apache-2.0' => cs.primaryContainer,
    'BSD-3-Clause' => cs.secondaryContainer,
    _ => cs.surfaceContainerHighest,
  };
}


class _LicenseBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _LicenseBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}


class _LicenseSheet extends StatelessWidget {
  final String package;
  final String version;
  final String license;
  final String text;

  const _LicenseSheet({
    required this.package,
    required this.version,
    required this.license,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: FrostedSheet(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.65,
          color: Colors.transparent,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            package,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$version · $license',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.ossCopyFullText,
                      icon: Icon(
                        Icons.copy_rounded,
                        color: cs.onSurfaceVariant,
                      ),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: text));
                        if (!context.mounted) return;
                        showAppToast(context, l10n.ossLicenseCopied);
                      },
                    ),
                    IconButton(
                      tooltip: l10n.scanClose,
                      icon: Icon(
                        Icons.close_rounded,
                        color: cs.onSurfaceVariant,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Container(
                height: 1,
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: SelectableText(
                    text,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.6,
                      color: cs.onSurface.withValues(alpha: 0.85),
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
