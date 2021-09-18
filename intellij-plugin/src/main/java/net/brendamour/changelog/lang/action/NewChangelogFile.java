package net.brendamour.changelog.lang.action;

import com.intellij.icons.AllIcons;
import com.intellij.ide.actions.CreateFileFromTemplateAction;
import com.intellij.ide.actions.CreateFileFromTemplateDialog;
import com.intellij.ide.fileTemplates.FileTemplate;
import com.intellij.ide.fileTemplates.FileTemplateManager;
import com.intellij.ide.fileTemplates.actions.AttributesDefaults;
import com.intellij.openapi.project.Project;
import com.intellij.openapi.project.ProjectUtil;
import com.intellij.openapi.util.NlsActions;
import com.intellij.openapi.util.NlsContexts;
import com.intellij.openapi.util.io.FileUtilRt;
import com.intellij.openapi.vfs.VirtualFile;
import com.intellij.psi.PsiDirectory;
import com.intellij.psi.PsiFile;
import com.intellij.psi.PsiManager;
import com.intellij.psi.impl.file.PsiDirectoryFactory;
import org.jetbrains.annotations.NonNls;
import org.jetbrains.annotations.NotNull;

import javax.swing.*;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;

public class NewChangelogFile extends CreateFileFromTemplateAction {
    public NewChangelogFile() {
        super("New Changelog File", "Add new Changelog file", AllIcons.FileTypes.Json);
    }

    public NewChangelogFile(@NlsActions.ActionText String text, @NlsActions.ActionDescription String description, Icon icon) {
        super(text, description, icon);
    }

    @Override
    protected void buildDialog(@NotNull Project project, @NotNull PsiDirectory directory, CreateFileFromTemplateDialog.@NotNull Builder builder) {
        builder
                .setTitle("New Changelog File")
                .addKind("JSON", AllIcons.FileTypes.Json, "Changelog");
    }

    @Override
    protected @NlsContexts.Command String getActionName(PsiDirectory directory, @NonNls @NotNull String newName, @NonNls String templateName) {
        return "Create Changelog File";
    }

    @Override
    protected PsiFile createFileFromTemplate(String name, FileTemplate template, PsiDirectory dir) {
        try {
            String className = FileUtilRt.getNameWithoutExtension(name);
            Project project = dir.getProject();
            Properties properties = createProperties(project, className);

            PsiDirectory changelogsDir = getChangelogsDir(project);

            AttributesDefaults defaults = new AttributesDefaults(className).withFixedName(true);
            defaults.add("Type", "added");
            Map<String, JComponent> typeMap = new HashMap<>();
            String[] validChangelogTypes = {"security",
                    "removed",
                    "fixed",
                    "deprecated",
                    "changed",
                    "performance",
                    "added",
                    "other"};
            typeMap.put("Type", new JComboBox<>(validChangelogTypes));
            return new CLCreateFromTemplateDialog(project, changelogsDir, template, defaults, properties, typeMap).create().getContainingFile();
        } catch (Exception e) {
            LOG.error("Error while creating new file", e);
            return null;
        }
    }

    @NotNull
    private PsiDirectory getChangelogsDir(Project project) throws IOException {
        VirtualFile projectDir = ProjectUtil.guessProjectDir(project);
        assert projectDir != null;
        assert projectDir.isWritable();


        VirtualFile changelogsDirVF = projectDir.findChild("changelogs");
        PsiDirectory changelogsDir;
        if (changelogsDirVF == null) {
            changelogsDirVF = projectDir.createChildDirectory(this, "changelogs");
            changelogsDir = PsiDirectoryFactory.getInstance(project).createDirectory(changelogsDirVF);
        } else {
            final PsiManager psiManager = PsiManager.getInstance(project);
            changelogsDir = psiManager.findDirectory(changelogsDirVF);
        }
        assert changelogsDir != null;
        return changelogsDir;
    }

    private @NotNull Properties createProperties(Project project, String className) {
        Properties properties = FileTemplateManager.getInstance(project).getDefaultProperties();
        return properties;
    }
}
