FROM nvidia/cuda:8.0-cudnn5-devel

MAINTAINER Matthewlujp

RUN apt-get -y update
RUN apt-get -y upgrade
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install build-essential git wget\
    pkg-config zlib1g-dev curl libbz2-dev libreadline-dev libssl-dev libsqlite3-dev\
    sudo vim zsh

# # Install java
RUN echo "\n\nInstals Java\n\n"
RUN apt-get -y install software-properties-common
RUN add-apt-repository -y ppa:webupd8team/java
RUN apt-get -y update
RUN echo debconf shared/accepted-oracle-license-v1-1 select true |  debconf-set-selections
RUN echo debconf shared/accepted-oracle-license-v1-1 seen true |  debconf-set-selections
RUN apt-get -y install -y oracle-java8-installer
#
# # Install bazel
RUN echo "\nInstall bazel"
RUN echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" |  tee /etc/apt/sources.list.d/bazel.list
RUN curl https://storage.googleapis.com/bazel-apt/doc/apt-key.pub.gpg |  apt-key add -
RUN apt-get -y update
RUN apt-get -y install bazel
RUN apt-get -y upgrade bazel

# Install pyenv
RUN echo "\nInstall pyenv"
WORKDIR /usr/local
RUN git clone git://github.com/yyuu/pyenv.git ./pyenv
RUN mkdir -p ./pyenv/versions ./pyenv/shims
WORKDIR /usr/local/pyenv/plugins
RUN git clone git://github.com/yyuu/pyenv-virtualenv.git
# Setup pyenv
RUN echo 'export PYENV_ROOT="/usr/local/pyenv"' | tee -a /etc/profile.d/pyenv.sh
RUN echo 'export PATH="${PYENV_ROOT}/shims:${PYENV_ROOT}/bin:${PATH}"' | tee -a /etc/profile.d/pyenv.sh
ENV PYENV_ROOT "/usr/local/pyenv"
ENV PATH="${PYENV_ROOT}/shims:${PYENV_ROOT}/bin:${PATH}"
RUN pyenv install -v 3.6.0

# Set PATH for sudo
WORKDIR /etc
RUN sed -i 's/^Defaults\ssecure_path=".*"/#&\nDefaults\tenv_keep += "PATH"\nDefaults\tenv_keep += "PYENV_ROOT"/' ./sudoers

# Create user
RUN useradd -m user
RUN echo "root:123456" | chpasswd
RUN echo "user:123456" | chpasswd
RUN adduser user sudo
# Working directory
WORKDIR /home/user
RUN mkdir ./mlenv
# Install packages for machine learning
WORKDIR /home/user/mlenv
RUN pyenv virtualenv 3.6.0 mlenv && pyenv local mlenv
RUN pyenv exec pip install numpy pandas scikit-learn ipython nose
RUN git clone https://github.com/tensorflow/tensorflow
WORKDIR /home/user/
# Settings for zsh
RUN curl https://raw.githubusercontent.com/matthewlujp/my_zsh_settings/master/.zshrc > .zshrc
RUN chsh -s `which zsh` user

USER user
CMD /bin/zsh
